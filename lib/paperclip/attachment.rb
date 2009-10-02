module Paperclip
  class Attachment
    attr_accessor :name, :options, :model

    def initialize(name, model, options = {})
      @name = name
      @model = model
      @options = options
      set_existing_paths
    end

    def assign(file)
      @queue_for_save   = []
      @queue_for_delete = []

      self.clear
      return if file.nil?

      write_model_attribute(:file_name,    File.basename(file.original_filename))
      write_model_attribute(:content_type, file.content_type)
      write_model_attribute(:file_size,    file.size)
      @queue_for_save = [file]
    end

    def present?
      not file_name.nil?
    end

    def file_name
      read_model_attribute(:file_name)
    end

    def content_type
      read_model_attribute(:content_type)
    end

    def file_size
      read_model_attribute(:file_size)
    end

    def read_model_attribute(attribute)
      @model.send(:"#{name}_#{attribute}")
    end

    def write_model_attribute(attribute, data)
      @model.send(:"#{name}_#{attribute}=", data)
    end

    def path
      Paperclip::Interpolations.interpolate(options[:path], self, :original)
    end

    def url
      if present?
        Paperclip::Interpolations.interpolate(options[:url], self, :original)
      else
        Paperclip::Interpolations.interpolate(options[:default_url], self, :original)
      end
    end

    def clear
      @queue_for_delete = [path] if present?
      write_model_attribute(:file_name,    nil)
      write_model_attribute(:content_type, nil)
      write_model_attribute(:file_size,    nil)
    end

    def set_existing_paths
      @existing_path = present? ? path : nil
    end

    def save
      flush_renames
      flush_writes
      flush_deletes
      set_existing_paths
    end

    def flush_writes
      @queue_for_save.each do |file|
        write(path, file)
      end
      @queue_for_save = []
    end

    def flush_deletes
      @queue_for_delete.each do |path|
        delete(path)
      end
      @queue_for_delete = []
    end

    def flush_renames
      if present? && ! @existing_path.nil? && (@existing_path != path)
        file = File.new(@existing_path)
        write(path, file)
        delete(@existing_path)
      end
    end

    def write(path, file)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w" ) do |f|
        f.write(file.read)
      end
    end

    def delete(path)
      File.delete(path)
    end
  end
end
