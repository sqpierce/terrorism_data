class Record
  
   # problem in Rails 2.0
#  include Reloadable

  def Record.write_graph(values, graph_type='scat', f2_keys=nil)
    file_type = RAILS_ENV == 'production' ? 'png' : 'gif'
    pl_bin = RAILS_ENV == 'production' ? "/Users/steve/sw/pl240macos/bin/pl" : "/Users/steve/sw/pl240macos/bin/pl"
    prefabs = RAILS_ENV == 'production' ? "/Users/steve/sw/pl240macos/prefabs" : "/Users/steve/sw/pl240macos/prefabs"
    
    image_file_dir = "#{RAILS_ROOT}/public/images/graphs"
    num = 0
    # delete old files
    Dir.entries(image_file_dir).each do |f|
      next unless f.match /^\w+\.\w+$/ # make sure it's not '.' or '..'
      fp = "#{image_file_dir}/#{f}"
      if (File.mtime(fp) + (60 * 60 * 24)) < Time.now # older than 24 hours?
        File.delete(fp)
      end
    end
    loop_count = 0
    while num == 0
      loop_count += 1
      break if loop_count > 1000 # just to be safe
      test = rand(1000).to_s
      unless File.exist? "#{image_file_dir}/#{test}.#{file_type}"
        num = test
      end
    end
    
    data_file_name = "#{num}.data"
    data_file_path = "#{RAILS_ROOT}/tmp/data/#{data_file_name}"
    image_file_name = "#{num}.#{file_type}"
    image_file_path = "#{image_file_dir}/#{image_file_name}"
    
    # write data file
    f = File.open(data_file_path, 'w')
    if f2_keys
      #f.write(values.inspect)
      values.keys.sort.each do |k|
        f.write( "#{k}" )
        f2_keys.sort.each do |k2|
          f.write( ", #{values[k][k2] || 0}" )
        end
        f.write( "\n" )
      end
    else
      values.sort.each do |x,y|
        f.write( "#{x}, #{y}\n" )
      end
    end
    f.close
  
    # note: file path must not have any spaces in it
        
    # generate graph
    # need a graph type to be passed in
    if graph_type == 'stack' and f2_keys #'stack_more'
      names = ''
      vars = ' x=1 y=2 '
      count=1
      f2_keys.sort.each do |k|
        names += count==1 ? " name=\"#{k}\" " : " name#{count.to_s}=\"#{k}\" "
        if count > 1
          vars += " y#{count}=#{count+1} "
        end
        count+=1
        break if count > 15 # can't do more than 15
      end
      RAILS_DEFAULT_LOGGER.warn(names)
      cmd_opts = "-prefab #{graph_type} -#{file_type} -o #{image_file_path} data=#{data_file_path} delim=comma #{vars} stubvert=yes #{names}"      
    elsif graph_type == 'scat'
      cmd_opts = "-prefab #{graph_type} -#{file_type} -o #{image_file_path} -maxrows 30000 data=#{data_file_path} delim=comma x=1 y=2 ptsize=0.02 cluster=yes corr=yes maxinpoints=30000"
    else
      cmd_opts = "-prefab #{graph_type} -#{file_type} -o #{image_file_path} data=#{data_file_path} delim=comma x=1 y=2 stubvert=yes"
    end
    begin
      cmd = "PLOTICUS_PREFABS='#{prefabs}' #{pl_bin} #{cmd_opts}"# >> tmp/pl.log 2>&1"
      RAILS_DEFAULT_LOGGER.warn(cmd)
      output = system( cmd )
      RAILS_DEFAULT_LOGGER.warn(output)
    rescue
      RAILS_DEFAULT_LOGGER.error($!)
    end
    
    return "graphs/#{image_file_name}"
  end


  def Record.do_query(key, options={})
    default_options = {:categorical => false, :conditions => nil, :count => false}
    options = default_options.merge options

    where_clause = options[:conditions] ? "where #{options[:conditions]}" : ""
    if options[:count]
      statement = "select count(#{key}) from records #{where_clause}"
    elsif options[:categorical]
      statement = "select distinct #{key}, count(#{key}) from records #{where_clause} group by #{key}"
    else
      case key
      when String
        statement = "select #{key} from records #{where_clause}"
      when Array
        statement = "select #{key.join(", ")} from records #{where_clause}"
      end
    end
    RAILS_DEFAULT_LOGGER.error(statement)
    SQLDB.execute(statement)
  end
  
  def Record.count(conditions=nil)
    Record.do_query( '*', :conditions => conditions, :count => true )
  end
  
  def Record.do_categorical(field, conditions=nil, count=false)
    records = Record.do_query( field, :categorical => true, :conditions => conditions )
    hash = {}
    total_with_unknowns = 0
    total_without_unknowns = 0
    records.map do |k,v|
      v=v.to_i
      hash[k]=v
      if k == 'Unknown'
        total_with_unknowns += v
      else
        total_with_unknowns += v
        total_without_unknowns += v
      end
    end
    [hash, total_with_unknowns, total_without_unknowns]
  end
  
  def Record.do_categorical_categorical(f1, f2, filepath, conditions=nil)
    records = Record.do_query( [f1,f2], :conditions => conditions )

    hash = {}
    f2_keys = []
    records.map do |x|
      v1 = x[0]
      v2 = x[1]
      f2_keys << v2
      hash[v1] = {} if not hash.has_key? v1
      hash[v1].has_key?(v2) ? hash[v1][v2] += 1 : hash[v1][v2] = 1
    end
    
    # sort the keys and eliminate unknowns
    f1_keys = hash.keys.sort.delete_if{ |x| x == 'Unknown' }
    f2_keys = f2_keys.uniq.sort.delete_if{ |x| x == 'Unknown' }
    
    #graph = SVG::Graph::Bar.new( :height => 300,:width => 500,:fields => f1_keys, :graph_title => "#{f1} and #{f2}", :show_graph_title => true, :rotate_x_labels=>true )    
    #f2_keys.each do |k2|
    #  vals = []
    #  f1_keys.each do |k|
    #    vals << (hash[k][k2] || 0)
    #  end
    #  graph.add_data( :data => vals, :title => "#{k2}" )   
    #end

    #f = File.open(filepath, 'w')
    #f.write(graph.burn)
    #f.close()
    
    #image_path = write_graph(hash, 'stack_more', f2_keys)
    image_path = write_graph(hash, 'stack', f2_keys)
    
    [hash, f2_keys, image_path]
  end

  def Record.do_interval(field, conditions=nil)
    vals = Record.get_interval_vals(field, conditions)
    Record.do_stats(vals)
  end
  
  def Record.sum(vals)
    total=0
    vals.map{ |x| total+= x }
    total
  end
  
  def Record.get_interval_vals(field, conditions=nil)
    case field
    when String
      conditions = conditions ? conditions << " AND #{field} != 'Unknown' " : " #{field} != 'Unknown' "
    when Array
      my_conditions = ''
      first = true
      field.each do |f|
        first ? my_conditions << " #{f} != 'Unknown' " : my_conditions << " AND #{f} != 'Unknown' "
        first = false
      end
      conditions = conditions ? conditions << " AND #{my_conditions} " : my_conditions
    end
    #RAILS_DEFAULT_LOGGER.error(conditions)
    vals = Record.do_query(field, :conditions => conditions).map{ |x| x[0].to_f }
  end

  # SP July 2008: pure Ruby stats
  def Record.do_stats(vals)
    total = vals.size # total is number of cases
    h = { 
      'mean' => vals.mean,
      'standard_deviation' => vals.stdev,
      'variance' => vals.variance,
      'min' => vals.min,
      'max' => vals.max,
      'median' => vals.median,
      #'upper_quartile' => sorted_vec.quantile_from_sorted_data(0.75),
      #'lower_quartile' => sorted_vec.quantile_from_sorted_data(0.25),
      'total' => total
    }
  end

  def Record.do_interval_interval(f1, f2, filepath, conditions=nil)
    conditions = conditions ? conditions << " AND #{f1} != 'Unknown' AND #{f2} != 'Unknown' " : "#{f1} != 'Unknown' AND #{f2} != 'Unknown' "
    records = Record.do_query( [f1,f2], :conditions => conditions )
    #records = [ [10,20], [3,4], [5,6], [10,11] ]

    #f = File.open(filepath, 'w')
    #graph = SVG::Graph::Plot.new( :height => 300,:width => 500,:fields => [ f1, f2 ], :rotate_x_labels => true, :show_data_values => false )
    
    # leave out filter with linear regression, as it skews line
    #unique = {}
    vals1 = []
    vals2 = []
    vals = []
    value_pairs = []
    records.each do |r|
      #next if unique.has_key? r
      vals1 << r[0].to_f
      vals2 << r[1].to_f
      vals << r[0].to_i
      vals << r[1].to_i
      value_pairs << [ r[0].to_i, r[1].to_i ]
      #unique[r] = 1
    end
    
    #if vals.size <= 1000
    #  graph.add_data( :data => vals, :title => "#{f1} (x) #{f2} (y)" )
    #else
    #  graph.add_data( :data => vals.slice(0,100), :title => "#{f1} (x) #{f2} (y) data truncated; first 1000 records shown" )
    #end
    # disabled show_data_values and took out line drawing from Plot.rb... seems to make it fast enough
    
    image_path = write_graph(value_pairs)
    
    #graph.add_data( :data => vals, :title => "#{f1} (x) #{f2} (y)" )
    
    #f.write(graph.burn)
    #f.close()

    # SP July 2008: pure Ruby stats
    hash={
      'covariance' => vals1.covariance(vals2),
      'correlation' => vals1.correlation(vals2),
    }
    hash['eta_squared'] = hash['correlation']*hash['correlation']
    [hash, image_path]
  end
  
  def Record.do_categorical_interval(cat_var, int_var, filepath, conditions=nil)
    conditions = conditions ? conditions << " AND #{cat_var} != 'Unknown' AND #{int_var} != 'Unknown' " : "#{cat_var} != 'Unknown' AND #{int_var} != 'Unknown' "
    records = Record.do_query( [cat_var,int_var], :conditions => conditions )
    #RAILS_DEFAULT_LOGGER.error("num records #{records.size}")
    
    # first get our numbers together
    tmp_hash={}
    records.map{ |x| k=x[0]; tmp_hash.has_key?(k) ? tmp_hash[k] << x[1].to_f : tmp_hash[k] = [x[1].to_f] }
    
    # then, do the stats per set
    hash = {}
    tmp_hash.map{ |k,v| hash[k] = Record.do_stats(v) }
    # then get our totals for calculating eta squared
    totals = Record.do_stats(records.map{ |x| x[1].to_f })
    
    # calculate eta squared
    group_sum_of_squares = hash.values.map{ |x| x['variance'].to_f*(x['total'].to_f-1.0) }
    numerator = Record.sum(group_sum_of_squares)
    denominator = totals['variance'].to_f*(totals['total'].to_f-1.0)
    eta_squared = 1.0 - (numerator / denominator)
    
    cat_keys = hash.keys.sort
    #graph = SVG::Graph::Bar.new( :height => 300,:width => 500,:fields => ['mean', 'std dev'] )
    
    data = []
    
    cat_keys.each do |k|
      # two different ways to set precision of float
      mean = sprintf("%.#{2}f", hash[k]['mean'].to_s).to_f
      stdev = (hash[k]['standard_deviation'] * 100).truncate.to_f / 100
      #graph.add_data( :data => [ mean, stdev ], :title => "#{k}" )
      data << [ k, mean ]
    end

    #f = File.open(filepath, 'w')
    #f.write(graph.burn)
    #f.close()

    image_path = write_graph( data, 'stack' )
    
    [hash, totals, eta_squared, image_path]
  end
  
end

