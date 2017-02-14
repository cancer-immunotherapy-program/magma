class Magma
  class ModelListPredicate < Magma::Predicate
    # ModelList predicate - this is what the query will start with, probably
    #
    # "sample"
    #
    # This is a request for all objects of type "sample", so it's return type should be:
    #   [ Sample ]
    # 

    # This object takes several arguments:
    #   1) It can accept an arbitrary list of filters, which are
    #      in the form of lists, e.g.:
    #
    #      [ "patient", "experiment", "name", "::equals", "Colorectal" ]
    #      [ "patient", "clinical", "parameter", [ "name", "::equals", "Gender" ], "::first", "value", "::equals", "Male" ]
    #
    #      Each one of these filters must reduce to a Boolean, or else it is
    #      invalid.  They must come first.
    #
    #   2) It can be reduced by a list operator. The list operators are:
    #      ::any - a Boolean that returns true if the list is non-zero
    #      ::first - returns the first item in the list, namely a Model
    #      ::all - returns every item in the list, represented by a Model
    #      ::count - returns the number of items in the list

    attr_reader :model

    def initialize model, *predicates
      @model = model.is_a?(Magma::Model) ? model : Magma.instance.get_model(model)
      @filters = []

      while predicates.first.is_a?(Array)
        filter = ModelPredicate.new(@model, *predicates.shift)
        raise "Filter #{filter} does not reduce to TrueClass #{filter.argument} #{filter.reduced_type}!" unless filter.reduced_type == TrueClass
        @filters.push filter
      end

      @predicates = predicates
      @child_predicate = get_child
    end

    def join
      joins = []
      @filters.each do |filter|
        joins.concat filter.join
      end
      joins.concat super
    end

    def filter 
      collection = []
      @filters.each do |filter|
        collection.concat filter.filter
      end
      collection.concat super
    end

    private

    def get_child
      @argument = @predicates.shift

      invalid_argument! unless @argument

      case @argument
      when "::any"
        return terminal(TrueClass)
      when "::first", "::all"
        return ModelPredicate.new(@model, *@predicates)
      when "::count"
        return terminal(Integer)
      else
        invalid_argument! @argument
      end
    end
  end
end