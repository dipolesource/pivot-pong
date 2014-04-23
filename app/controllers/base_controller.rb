class BaseController < ApplicationController
  helper_method :collection
  respond_to :html, :json

  def self.using_service service_class
    define_method(:service) { service_class }
  end

  def self.decorate_with decorator_class
    define_method(:decorator) { decorator_class }
  end

  def self.page_size size
    define_method(:page_size) { size }
  end

  def index
    respond_to do |format|
      format.js { render json: { results: collection.as_json } }
      format.html { respond_with collection }
    end
  end

  def create
    resource = service.new(safe_params)
    respond_to do |format|
      if resource.save
        format.js { render json: resource }
      else
        format.js { render status: 400, json: resource }
      end
      format.html { redirect_to root_path, alert: resource.errors.full_messages }
    end
  end

  protected

  def set_collection(collection_object = nil)
    @collection = decorate(paged(collection_object || default_collection))
  end

  def collection
    unless @collection
      @collection = decorate(paged(default_collection))
    end
    @collection
  end

  def page_size
    10
  end

  private

  def safe_params
    raise NotImplementedError, 'Subclasses of BaseController need to define #safe_params!'
  end

  def default_collection
    service.all
  end

  def paged(collection_object)
    collection_object.page(params[:page]).per(page_size)
  end

  def decorate(collection_object)
    if decorator
      PaginatingDecorator.decorate(collection_object, with: decorator)
    else
      collection_object
    end
  end

  # call decorate_with in your controller
  # to set and use a decorator
  def decorator
    nil
  end
end
