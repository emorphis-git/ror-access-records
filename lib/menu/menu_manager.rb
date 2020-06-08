module Menu::MenuManager
  def self.items(menu_name)
    items = {}
    mapper = Mapper.new(menu_name.to_sym, items)
    potential_items = @menu_builder_queues[menu_name.to_sym]
    potential_items += @temp_menu_builder_queues[menu_name.to_sym] if @temp_menu_builder_queues and @temp_menu_builder_queues[menu_name.to_sym]

    @temp_menu_builder_queues = {}

    potential_items.each do |menu_builder|
      menu_builder.call(mapper)
    end

    items[menu_name.to_sym]
  end
end
