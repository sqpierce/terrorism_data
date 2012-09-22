class DataController < ApplicationController

  @@TEMPLATE_DIR = 'data'
  
  def summary
    @conditions_variables = Variable.find(:all)
    @summary_variables = Array.new(@conditions_variables)
    @summary_variables.delete_if{ |x| x.level == 'date' }
    session[:conditions] = nil
    @conditions = nil
  end
  
  def conditions_builder
    @conditions_field = request.raw_post || request.query_string
    @field_type = Variable.find_by_name(@conditions_field).level
    @categories = Record.do_query(@conditions_field, :categorical=>true).map{ |x| x[0] } if @field_type == 'categorical'
    session[:conditions_field] = @conditions_field
  end
  
  def add_condition
    condition_key = session[:conditions_field]
    condition_value = "#{session[:conditions_field]} #{params[:conditions_operator]} '#{params[:conditions_target]}'"
    
    session[:conditions] = {} unless session[:conditions]

    unless session[:conditions].values.map{ |x| x.include? condition_value }.include? true
      session[:conditions].has_key?(condition_key) ? session[:conditions][condition_key] << condition_value : session[:conditions][condition_key] = [ condition_value ]
    end

    @conditions = conditions_string
    @conditions_display = conditions_string_display
    render :template => "#{@@TEMPLATE_DIR}/show_conditions"
  end

  def clear_conditions
    @conditions = nil
    @conditions_display = nil
    session[:conditions] = nil
    render :template => "#{@@TEMPLATE_DIR}/show_conditions"
  end

  def summarize
    @field = params[:field_value]
    field_name = params[:field_name]
    unless @field
      if params[:field1]
        @field = params[:field1]
        field_name = 'field1'
      elsif params[:field2]
        @field = params[:field2]
        field_name = 'field2'
      end
    end

    unless @field and @field != ' -- select field -- '
      @error = 'You must select a valid field.'
      render :template => "#{@@TEMPLATE_DIR}/error" and return      
    end
    
    type = Variable.find_by_name(@field).level
    session[field_name] = @field
    @conditions = conditions_string
    
    case type
    when 'categorical'
      (@results, @total_with_unknowns, @total_without_unknowns) = Record.do_categorical(@field, @conditions)
      render :template => "#{@@TEMPLATE_DIR}/categorical_summary"
    when 'interval'
      @conditions = conditions_string
      @results = Record.do_interval(@field, @conditions)
      render :template => "#{@@TEMPLATE_DIR}/interval_summary"
    end
  end
  
  def correlate
    # results hash should be summary of data
    # this is categorical on categorical
    @field1 = session['field1']
    @field2 = session['field2']
    
    if @field1 == @field2
      @error = 'Relationship not valid where fields are the same.'
      render :template => "#{@@TEMPLATE_DIR}/error" and return
    end
    
    unless @field1 and @field2
      @error = 'You must make a selection for both fields.'
      render :template => "#{@@TEMPLATE_DIR}/error" and return      
    end
    
    type1 = Variable.find_by_name(@field1).level
    type2 = Variable.find_by_name(@field2).level
    @conditions = conditions_string

    filepath = nil  

    case [ type1, type2 ]
    when [ 'categorical', 'categorical' ]
      ( @results, @f2_keys, @image_path ) = Record.do_categorical_categorical(@field1, @field2, filepath, @conditions)
      unless @results
        render :template => "#{@@TEMPLATE_DIR}/image_error" and return
      end
      render :template => "#{@@TEMPLATE_DIR}/table"
    when [ 'interval', 'interval' ]
      ( @results, @image_path ) = Record.do_interval_interval(@field1, @field2, filepath, @conditions)
      unless @results
        render :template => "#{@@TEMPLATE_DIR}/image_error" and return
      end
      render :template => "#{@@TEMPLATE_DIR}/correlation"
    else
      @cat_var = type1 == 'categorical' ? @field1 : @field2
      @int_var = type1 == 'interval' ? @field1 : @field2
      ( @results,@totals, @eta_squared, @image_path ) = Record.do_categorical_interval(@cat_var, @int_var, filepath, @conditions)
      unless @results
        render :template => "#{@@TEMPLATE_DIR}/image_error" and return
      end
      render :template => "#{@@TEMPLATE_DIR}/table2"
    end
  end
  
  def download
    keys = Variable.find(:all).map{ |x| x.name }
    _csv( keys, Record.do_query(keys, :conditions => conditions_string) )
  end
  
  private
  
  def conditions_string
    return nil unless session[:conditions]
    strs=[]
    session[:conditions].map do |k,v|
      k_level = Variable.find_by_name(k).level
      conjunction = k_level == 'categorical' ? ' OR ' : ' AND '
      k_level == 'interval' ? strs << "(#{ v.join(conjunction) } AND #{k} != 'Unknown')" : strs << "(#{ v.join(conjunction) })"
    end
    strs.join(' AND ')
  end

  def conditions_string_display
    return nil unless session[:conditions]
    strs=[]
    session[:conditions].map do |k,v|
      k_level = Variable.find_by_name(k).level
      conjunction = k_level == 'categorical' ? ' OR ' : ' AND '
      strs << "(#{ v.join(conjunction) })"
    end
    strs.join(' AND ')
  end

end
