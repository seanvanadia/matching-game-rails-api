# frozen_string_literal: true

module Api
  module V1
    # V1 Categories Controller
    class CategoriesController < ApplicationController
      before_action :authenticate_user!
      before_action :logout_if_timedout
      before_action :set_category, except: %i[index create]

      def index
        # If there is no pg_num param,
        # render all the user's categories and return
        render(json: current_user.categories) && return unless params[:pg_num]

        # If a pg_num param exists...

        pg_num = params[:pg_num].to_i
        num_cats = params[:num_cats].to_i
        length = current_user.categories.length
        start_index = num_cats * (pg_num - 1)

        # Workaround for AMS bug when dealing with empty arrays:
        # If the page's categories array is empty, force it to render,
        # as well as desired meta data
        if current_user.categories[start_index, num_cats] == []
          render json: {
            categories: current_user.categories[start_index, num_cats],
            meta: { length: length, pageNumber: pg_num }
          }

        # If the page's categories array is not empty...
        else
          # Initial serializer value is standard category serializer
          serializer = CategorySerializer

          # If titles_only param exists, set the serializer value
          # as the category title serializer
          if params[:titles_only]
            serializer = CategoryTitleSerializer
            num_cats += 1 if params[:add_one_cat] == 'true'
          end

          # Render either the user's page of categories or category titles,
          # as well as meta data
          render json:
            current_user.categories[start_index, num_cats],
                 each_serializer: serializer,
                 meta: { length: length, pageNumber: pg_num },
                 adapter: :json
        end
      end

      def create
        # Build the new category
        @category = current_user.categories.build(category_params)

        # If the category is successfully saved...
        if @category.save
          non_cat_images = []
          img_keys = %w[created_at id image image_file_name updated_at]

          # Create the category's first page of non_cat_images
          current_user.images[0..(params[:num_imgs].to_i - 1)].each do |img|
            image = {}
            5.times do |i|
              # "image" prop needs special assignment due to paperclip
              if i == 2
                image['image'] = img.image
              else
                image[img_keys[i]] = img[img_keys[i]]
              end
            end

            non_cat_images.push(image)
          end

          # Render the created category and its first page of nonCatImages
          # as meta data
          render json:
            @category,
                 meta: {
                   length: current_user.images.length,
                   nonCatImages: non_cat_images
                 },
                 adapter: :json, status: 201

        # If there is an error while adding the category...
        else
          render json: { errors: @category.errors.full_messages }, status: 422
        end
      end

      def show
        @category ||= current_user.categories.first

        # If the user does not have a first category, return nil
        return nil unless @category

        # If the user has a first category...

        pg_num = params[:pg_num].to_i
        num_imgs = params[:num_imgs].to_i

        # If a page of category images is being fetched...
        if pg_num != 0
          length = @category.images.length

          # Initial value of the last_page is assuming the number of images
          # requested does not divide evenly into the total number of images
          last_page = (length / num_imgs) + 1

          # If the number of images requested divides evenly into the total
          # number of images, there are no extra (remainder) images on the
          # final page, so subtract one from the last page number
          last_page -= 1 if (length % num_imgs).zero?

          # If the requested page number is greater than the last_page number,
          # revert to page number 1
          pg_num = 1 if pg_num > last_page

          # Store the page's start index
          start_index = num_imgs * (pg_num - 1)

          # Change the num_imgs if the pg_num is the last page
          # (since the last page may not be filled)
          num_imgs = length - start_index if pg_num == last_page

          # Render the category, including meta data
          render json:
            @category, start_index: start_index, num_imgs: num_imgs,
                 meta: {
                   length: length,
                   pageNumber: pg_num,
                   catIndex: current_user.categories.index(@category)
                 },
                 adapter: :json

        # If img_indexes param is null...
        elsif params[:img_indexes] == 'null'
          length = @category.images.length
          end_num = length - 1

          # Array of random indexes for images
          img_indexes = (0..end_num).to_a.sample(num_imgs)

          # Render the requested category and meta data
          render json:
            @category, img_indexes: img_indexes,
                 meta: {
                   length: length,
                   imgIndexes: img_indexes,
                   catIndex: current_user.categories.index(@category)
                 },
                 adapter: :json

        # If img_indexes param was passed in...
        elsif params[:img_indexes] != 'null'
          img_indexes = params[:img_indexes].split(',')

          # Render the specific images requested as part of the category
          render json:
            @category, img_indexes: img_indexes,
                 meta: {
                   length: length,
                   imgIndexes: img_indexes,
                   catIndex: current_user.categories.index(@category)
                 },
                 adapter: :json

        # If no page number or img_indexes were passed in...
        else
          length = @category.images.length

          # Initial value of the last_page is assuming the number of images
          # requested does not divide evenly into the total number of images
          last_page = (length / num_imgs) + 1

          # If the number of images requested divides evenly
          # into the total number of images, there are no extra (remainder)
          # images on the final page, so subtract one from the last page number
          last_page -= 1 if (length % num_imgs).zero?

          # If the requested page number is greater than the last_page number,
          # revert to page number 1
          pg_num = 1 if pg_num > last_page

          # Store the page's start index
          start_index = num_imgs * (pg_num - 1)

          # Change the num_imgs if the pg_num is the last page
          # (since the last page may not be filled)
          num_imgs = length - start_index if pg_num == last_page

          # Render the category, including meta data
          render json:
            @category, start_index: start_index, num_imgs: num_imgs,
                 meta: {
                   length: length,
                   pageNumber: pg_num,
                   catIndex: current_user.categories.index(@category)
                 },
                 adapter: :json
        end
      end

      def update
        # If a title paramater is received, update the category title
        if params[:title]

          # If the category's title is successfully updated...
          if @category.update_attribute(:title, params[:title])
            render json: @category, status: 200

          # If there was an error while updating the category's title...
          else
            render json: { errors: @category.errors.full_messages }, status: 400
          end

        # If a title paramater was not received, update the category's images
        else
          update_category_requests = []
          update_image_requests = []
          all_updated = true # Set to true initially as a reference point

          # For each of the images to be updated...
          params[:image_ids].each do |image_id|
            image = current_user.images.find(image_id)

            # If the image belongs to the category, remove it from the category
            update_category_request = if @category.images.include? image
                                        @category.images.delete(image)

                                      # If the image does not belong to the category,
                                      # add it to the category
                                      else
                                        @category.update_attributes(
                                          images: @category.images.push(image)
                                        )
                                      end

            # Update the image's updated_at property
            update_image_request = image.update_attribute(:updated_at, Time.now)

            update_image_requests << update_image_request
            all_updated &&= update_image_request

            update_category_requests << update_category_request
            all_updated &&= update_category_request
          end

          # If all of the category's images were updated...
          if all_updated
            render json:
              @category, serializer: CategoryTitleSerializer, status: 200

          # If there were errors while updating the category's images,
          # render the errors
          else
            render json: update_category_requests.map(&:errors), status: 400
          end

        end
      end

      def destroy
        # If the category is successfully destroyed...
        if @category.destroy
          # If num_imgs requested is greater than zero...
          if params[:num_imgs].to_i.positive?
            num_imgs = params[:num_imgs].to_i
            num_cat_imgs =
              current_user.categories.first.images[0, num_imgs].length
            num_non_cat_imgs = num_imgs - num_cat_imgs

            # Define the non_cat_images
            real_non_cat_images = []
            if num_non_cat_imgs.positive?
              non_cat_images = []

              current_user.images.each do |image|
                # Image is a non_cat_image if it contains no categories
                non_cat_images.push(image) if image.categories == []

                image.categories.each_with_index do |category, index|
                  # If category belongs to image,
                  # break the inner loop to move to the next image
                  break if category.id == current_user.categories.first.id

                  # If the last image's category has been checked and the image
                  # does not contain the submitted category, add the image to
                  # the non_cat_images array
                  non_cat_images.push(image) if index == image.categories.length - 1
                end

                # Break the loop once enough non_cat_imgs have been found
                break if non_cat_images.length == num_non_cat_imgs
              end

              # Declare non_cat_images with proper properties...

              img_keys = %w[created_at id image image_file_name updated_at]

              # Create the category's first page of non_cat_images
              non_cat_images.each do |img|
                image = {}
                5.times do |i|
                  # "image" prop needs special assignment due to paperclip
                  if i == 2
                    image['image'] = img.image
                  else
                    image[img_keys[i]] = img[img_keys[i]]
                  end
                end

                real_non_cat_images.push(image)
              end
            end

            # Define the category images length
            cat_images_length = current_user.categories.first.images.length

            # Define the replacement category title
            replacement_cat_title = nil
            if params[:cat_title_index] != 'null'
              replacement_cat =
                current_user.categories[params[:cat_title_index].to_i]
              replacement_cat_title = {
                id: replacement_cat.id,
                created_at: replacement_cat.created_at,
                title: replacement_cat.title
              }
            end

            # Render the user's first category, and meta data,
            # including the replacement category title
            render json:
              current_user.categories.first, start_index: 0, num_imgs: num_imgs,
                   meta: {
                     nonCatImages: real_non_cat_images,
                     catImagesLength: cat_images_length,
                     nonCatImagesLength:
                  current_user.images.length - cat_images_length,
                     replacementCatTitle: replacement_cat_title
                   },
                   adapter: :json, status: 200

          # If no num_imgs are requested, respond with head(:ok)
          else
            head(:ok)
          end

        # If there is an error while destroying the category...
        else
          head(:unprocessable_entity)
        end
      end

      private

      def set_category
        # If this is the first request from the game page,
        # make @category the first category with at least two images
        if params[:first_game_request] == 'true'
          @category = nil
          current_user.categories.each do |category|
            if category.images.length >= 2
              @category = category
              break
            end
          end

        # If this is the first request from the categories page...
        elsif params[:first_cats_request] == 'true'
          @category = nil

          # If no specific id is passed in, @category is the first category
          if params[:id] == 'null'
            @category = current_user.categories.first

          # If an id is passed in, @category is the category associated
          # with that id, unless it doesn't exist
          else
            id = params[:id].to_i

            current_user.categories.each do |cat|
              if cat.id == id
                @category = cat
                break
              end
            end
          end

        # If this is not the first game request or first categories request,
        # @category is the category associated with the id passed in
        else
          @category = current_user.categories.find(params[:id])
        end
      end

      def category_params
        params.permit(:title, :images)
      end
    end
  end
end
