module Trucker
  class Model
    attr_accessor :name, :options
    def initialize(name, options)
      @name = name.to_s.classify
      @options = options
    end

    def query
      eval construct_query
    end
    def construct_query
      if options[:limit] or options[:offset] or options[:where]
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

  class Migration
    def initialize(name, options = {})
      @model = Model.new(name, options)
      @label = options[:label]
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
      status += "#{ENV['limit'].blank? ? "all" : ENV['limit']} #{@label || @model.name}"
      status += " after #{@model.offset}" if @model.offset
      status
    end
    def import_counter
      counter = 0
      counter += @model.offset.to_i if @model.offset
      counter
    end
    def import
      @model.query.each do |record|
        @counter += 1
        puts @status + " (#{@counter}/#{@total_records})"
        record.migrate
      end
    end
  end

  def self.model_options
      model_options = {}
      model_options[:where] = ENV['where']
      model_options[:limit] = ENV['limit']
      model_options[:offset] = ENV['offset']
  end

  def self.migrate(name, options={})
    # Grab custom entity label if present
    label = options.delete(:label) if options[:label]

    unless options[:helper]
      @migration = Migration.new(name, model_options.merge({:label => options[:label]}))
      @migration.destroy_nonlegacy_records # this can now be made optional
      @migration.import

      # here is exactly how you do it. you inherit from that fucker, override import, and
      # add a where which scopes to user_id
      #
      #   @nested_migration = NestedMigration.new(:image_records, :where => "'user_id = 8403'")
      #   @nested_migration.import

      # or even
      # class UserMigration < Migration
      #   def import
      #     # everything as normal...
      #     @nested_migration = NestedMigration.new(:image_records, :where => "'user_id = 8403'")
      #     @nested_migration.import
      #   end
      # end

      # or, you know what, since user_ids are coming through the same, I might as well just import
      # a ton of users and a ton of image records and see what happens.

    else
      eval options[:helper].to_s
      # these can now be subclasses of Migration, so you get a lot of stuff for free
    end
  end
end

