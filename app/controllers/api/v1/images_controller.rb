# frozen_string_literal: true

module Api
  module V1
    # V1 Images Controller
    class ImagesController < ApplicationController
      before_action :authenticate_user!
      before_action :logout_if_timedout
      before_action :set_image, except: %i[index create]

      def index
        pg_num = params[:pg_num].to_i
        num_imgs = params[:num_imgs].to_i
        offset = params[:offset] ? params[:offset].to_i : 0
        cat_id = params[:cat_id] ? params[:cat_id].to_i : nil
        img_indexes = []
        images = current_user.images

        # If no images were requested, return the length of images
        if num_imgs.zero?
          length = current_user.images.length -
                   current_user.categories.find(cat_id).images.length

          render(json: { images: [], meta: { length: length } }) && return
        end

        # If the cat_id param is passed in...
        if cat_id
          non_cat_images = []

          # Define non_cat_images and img_indexes
          images.each_with_index do |image, img_index|
            if image.categories == []
              non_cat_images.push(image)
              img_indexes.push(img_index)
            end

            image.categories.each_with_index do |category, index|
              # If category belongs to image, break the inner loop
              # to move to the next image
              break if category.id == cat_id

              # If the last image's category has been checked and the image
              # does not contain the submitted category, add the image to
              # the non_cat_images array
              if index == image.categories.length - 1
                non_cat_images.push(image)
                img_indexes.push(img_index)
              end
            end
          end

          # Set the images to be rendered as the non_cat_images array
          images = non_cat_images
        end

        # Define the images array length
        length = images.length

        # Initial value of the last_page is assuming the number of images
        # requested does not divide evenly into the total number of images
        last_page =
          if offset.positive?
            ((length - offset) / num_imgs) + 2
          else
            (length / num_imgs) + 1
          end

        # If the number of images requested divides evenly into the total
        # number of images, there are no extra (remainder) images on the final
        # page, so subtract one from the last page number
        last_page -= 1 if ((length - offset) % num_imgs).zero?

        # If the requested page number is greater than the last_page number,
        # revert to page number 1
        pg_num = 1 if pg_num > last_page

        # Store the page's start index
        if pg_num == 1
          start_index = 0

          num_imgs = offset if cat_id

        else
          start_index =
            if offset.positive?
              offset + (num_imgs * (pg_num - 2))
            else
              num_imgs * (pg_num - 1)
            end
        end

        # Change the num_imgs if the pg_num is the last page
        # (since the last page may not be filled)
        num_imgs = length - start_index if pg_num == last_page

        # Workaround for AMS bug when dealing with empty arrays:
        # If the page's images array is empty, force it to render,
        # as well as desired meta data
        if images[start_index, num_imgs] == []
          render json: {
            images: images[start_index, num_imgs],
            meta: {
              imgIndexes: img_indexes[start_index, num_imgs],
              length: length,
              pageNumber: pg_num
            }
          }

        # If the page's images array is not empty, render the user's page of
        # images, as well as desired meta data
        else
          each_serializer =
            cat_id ? ImageWithoutCategoriesSerializer : ImageSerializer

          render json:
            images[start_index, num_imgs], each_serializer: each_serializer,
                 meta: {
                   imgIndexes: img_indexes[start_index, num_imgs],
                   length: length,
                   pageNumber: pg_num
                 },
                 adapter: :json
        end
      end

      def create
        categories = []
        category_ids = params[:category_ids].split(',')

        # Create an array of the images' categories
        category_ids.each do |category_id|
          categories << current_user.categories.find(category_id)
        end

        # Build the image
        @image =
          current_user.images.build(
            image: params[:image], categories: categories
          )

        # Attach the image file name to the image
        @image.image_file_name = params[:file_name]

        # If the image is successfully saved...
        if @image.save
          render json: @image, status: 201

        # If there was an error saving the image...
        else
          render json: { errors: @image.errors.full_messages }, status: 422
        end
      end

      def show
        # If a page number was passed in, render the image data and its
        # appropriate categories
        if params[:pg_num]
          pg_num = params[:pg_num].to_i
          length = @image.categories.length
          start_index = 10 * (pg_num - 1)

          # Render either the user's image, as well as meta data
          render json:
            @image, start_index: start_index,
                 meta: { length: length, pageNumber: pg_num },
                 adapter: :json

        # If no page number was passed in, send a temporary url of the
        # requested image (expires 60 seconds after request)
        else
          send_file URI.parse(@image.image.expiring_url(60)).open,
                    # Attach content-type of image
                    type: @image.image_content_type,
                    # Do not download the file to the user's local file system
                    disposition: 'inline'
        end
      end

      def update
        update_image_requests = []
        all_updated = true # Set to true initially as a reference point

        # For each of the submitted category ids...
        params[:category_ids].each do |category_id|
          category = current_user.categories.find(category_id)

          # If the submitted category belongs to the image,
          # delete it from the image
          if @image.categories.include? category
            @image.categories.delete(category)

            update_image_request = @image.update_attributes(
              categories: @image.categories, updated_at: Time.now
            )

          # If the submitted category does not belong to the image,
          # add it to the image
          else
            update_image_request = @image.update_attributes(
              categories: @image.categories.push(category), updated_at: Time.now
            )
          end

          update_image_requests << update_image_request
          all_updated &&= update_image_request
        end

        # If all of the image's categories were successfully updated...
        if all_updated
          render json: @image, status: 200

        # If there were errors while updating the image, render the errors...
        else
          render json: update_image_requests.map(&:errors), status: 400
        end
      end

      def destroy
        replacement_img = nil

        # If a replacement image is requested, store the replacement image
        if params[:replacement_img_index] != 'null'
          replacement_img =
            current_user.images[params[:replacement_img_index].to_i]
        end

        # If the image is successfully destroyed...
        if @image.destroy
          # If a replacement image exists, render the replacement image
          if replacement_img
            render json: replacement_img, status: 200

          # Else return status ok
          else
            head(:ok)
          end

        # If there is an error while destroying the image,
        # return status unprocessable entity
        else
          head(:unprocessable_entity)
        end
      end

      private

      def set_image
        @image = current_user.images.find(params[:id])
      end
    end
  end
end
