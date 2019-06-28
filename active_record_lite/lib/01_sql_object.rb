require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

require 'byebug'

class SQLObject
  def self.columns
    #lazy initialization ||= so that the query is not done multiple times. Only queries the DB once
    #execute2 returns an array where the first element is an array of column names. execute will not return this.
    @array ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    #sets the array variable to the mapped array so that we do not need to map everytime we call columns.
    @columns = @array.first.map(&:to_sym) #turns each string element ["id", "name", "owner_id"] into a symbol [:id, :name, :owner_id]
  end

  def self.finalize!
    self.columns.each do |column|
      define_method column do
        self.attributes[column]
      end

      define_method "#{column}=" do |arg|
        self.attributes[column] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    return "#{self}".tableize if @table_name.nil?
    @table_name
  end

  def self.all
    @all = DBConnection.execute(<<-SQL)
      SELECT
        * 
      FROM
        #{self.table_name}
    SQL
    @obj_list = self.parse_all(@all)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    @single = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    self.parse_all(@single).first
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute \'#{k.to_sym}\'" if !self.class.columns.include?(k.to_sym)
      self.send("#{k.to_sym}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    col_names = self.class.columns.join(',')
    question_marks = ["?"] * col_names.length
    
    DBConnection.execute(<<-SQL)
      INSERT INTO
        self.table_name(col1, col2, col3)
      VALUES
        (?, ?, ?)
    SQL
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
