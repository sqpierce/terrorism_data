# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  #def authorized?
  #  return true
  #end
  
  def _csv(keys, records)
    content_type = if request.user_agent =~ /windows/i
                     'application/vnd.ms-excel'
                   else
                     'text/csv'
                   end
    
    CSV::Writer.generate(output = "") do |c|
      c << keys
      records.each do |record|
        c << record
      end
    end

    send_data(output, 
              :type => content_type, 
              :filename => "download.csv")
  end

end
