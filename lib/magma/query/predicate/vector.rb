class Magma
  # just like the ModelPredicate, this keeps track of its own predicate chain.
  # Confusing... Perhaps a better concept is in order?
  class VectorPredicate < Magma::Predicate
    def initialize model, alias_name, columns, *predicates
      @model = model
      @alias_name = alias_name
      @columns = columns
      @predicates = predicates
      @child_predicate = get_child
    end

    def extract table, identity
      @column_predicates.map do |pred|
        pred.extract(table,identity)
      end
    end

    def join
      s = @column_predicates.map do |pred|
        pred.flatten.map(&:join).inject(&:+)
      end.inject(&:+)
      s
    end

    def select
      @column_predicates.map do |pred|
        pred.flatten.map(&:select).inject(&:+)
      end.inject(&:+)
    end

    private

    def get_child
      raise ArgumentError, "Column vector cannot be empty!" if @columns.empty?
      @column_predicates = @columns.map do |column_query|
        # now, we merely map this to a record predicate. Handy!
        RecordPredicate.new(@model, @alias_name, *column_query)
      end
      return terminal(Array)
    end
  end
end
