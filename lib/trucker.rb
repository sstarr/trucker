module Trucker
  class Model
    attr_accessor :name
    def initialize(name)
      @name = name.to_s.classify
    end

    def query
      eval construct_query
    end
    def construct_query
      if ENV['limit'] or ENV['offset'] or ENV['where']
        complete = base + "#{where}#{limit}#{offset}"
      else
        complete = base + ".all"
      end
      complete
    end
    def base
      "Legacy#{@name.classify.split(" ").join}"
    end

    def batch(method)
      nil || ".#{method}(#{ENV[method]})" unless ENV[method].blank?
    end
    def where
      batch("where")
    end
    def limit
      batch("limit")
    end
    def offset
      batch("offset")
    end
  end

  class Migrator
    def initialize(name)
      @model = Model.new(name)
      @counter = import_counter
      @total_records = "#{@model.base}".constantize.count
      @status = status_message
    end
    def destroy_nonlegacy_records
      @model.name.to_s.constantize.delete_all
    end
    def status_message
      status = "Migrating "
      # this next line is fucked because it fails to accomodate offsets
      status += "#{ENV['limit'].blank? "all" : ENV['limit']} #{label || @model.name}"
      status += " after #{@model.offset}" if @model.offset
    end
    def import_counter
      counter = 0
      counter += @model.offset.to_i if @model.offset
    end
    def import
      @model.query.each do |record|
        @counter += 1
        puts @status + " (#{@counter}/#{@total_records})"
        record.migrate
      end
    end
  end

  def self.migrate(name, options={})
    # Grab custom entity label if present
    label = options.delete(:label) if options[:label] # this got left out of the refactor!

    unless options[:helper]

      @model = Model.new(name)
      @migrator = Migrator.new(name)
      @migrator.destroy_nonlegacy_records # this can now be made optional
      @migrator.import

    else
      eval options[:helper].to_s
    end
  end
end

