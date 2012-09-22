# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_percentage(val, total)
    percentage = (val.to_f/total.to_f)*100.0
    number_to_percentage( percentage, { :precision => 2 } )
  end
  
  def display_conditions
    count = Record.count(@conditions)
    return "<p>None (#{count} incidents)</p>" unless @conditions
    escape_javascript(
      """
      <p>
        #{@conditions_display} (#{count} incidents)
      </p>
      """
      )
  end
  
end
  