module Concerns::Layout
  extend ActiveSupport::Concern

  included do
    def layout_non_or_no_menu
      if request.xhr?
        false
      elsif @project
        true
      else
        'no_menu'
      end
    end
  end
end
