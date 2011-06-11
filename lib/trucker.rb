module Trucker
  class Model
    attr_accessor :name
    def initialize(name)
      @name = name
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
      # this might look baffling, so check the specs. String#titlecase is badly named (in
      # my opinion) because in addition to title-casing, it also arrogantly adds a space
      "Legacy#{@name.singularize.titlecase.split(" ").join}"
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

  def self.migrate(name, options={})
    # Grab custom entity label if present
    label = options.delete(:label) if options[:label]

    unless options[:helper]
  
      # Grab model to migrate
      @model = Model.new(name)
  
      # Wipe out existing records
      @model.name.to_s.classify.constantize.delete_all

      # Status message
      status = "Migrating "
      status += "#{@model.limit || "all"} #{label || @model.name}"
      status += " after #{@model.offset}" if @model.offset
  
      # Set import counter
      counter = 0
      counter += @model.offset.to_i if @model.offset
      total_records = "Legacy#{@model.name}".constantize.count
  
      # Start import
      @model.query.each do |record|
        counter += 1
        puts status + " (#{counter}/#{total_records})"
        record.migrate
      end
    else
      eval options[:helper].to_s
    end
  end
end

