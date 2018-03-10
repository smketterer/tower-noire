pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- tower noire
-- by cow

function _init()
	log = {{0,""},{0,"welcome to tower noire."},{0,"a game by cow."}}
	-- entity descriptions:
	-- 1: type
	-- 		0 block
	--		1 creature
	--		2 corpses and effects
	--		3 items
	-- 2: name
	-- 3: sprite
	-- 4: x
	-- 5: y
	-- 6: health
	-- 7: status effect
	entities = {{3,"sword",115,40,40},{3,"tride",116,48,40},{3,"tunic",112,32,40},{3,"snack",99,32,32},{3,"flask",101,40,32},{3,"snack",99,48,32},{0,"wizard",35,64,72,0,0},{0,"fire",31,72,72}}
	cursor = ">"
	show_menu = false
	show_prompt = false
	game_won = false
	camera_x = 0
	camera_y = 0
	room = 0

	player_can_move = true
	player_is_visible = true
	player_health = 28
	player_max_health = 28
	player_x = 40
	player_x_previous = 40
	player_y = 56
	player_y_previous = 56
	player_steps = 0
	player_kills = 0
	player_image = 0
	player_inventory = {{"hand","",45},{"body","",44},{"legs","",46},{"pocket","",62},{"pocket","",62},{"pocket","",62}}
	player_actions = {{cursor,"wear"},{"","throw"},{"","eat"},{"","drop"},{"","exit"}}

	player_stats = {str=0, def=0}
	player_effects = {"",""}
	wearable = {{"tunic",2,1},{"poncho",2,2},{"jokki",2,3},{"exomis",2,4},{"sword",1,0,7},{"sword+3",1,0,10},{"gavel",1,0,5,"bash"},{"estoc",1,0,5,"parry"},{"tride",1,0,2,"sticky"},{"boots",3,1},{"socks",3,1}} --name, equip slot, def amount, str amount, other effect
	breakable = {{"snack",1,"",0.5},{"flask",-2,"",0.95}} --name, damage, other effect, probability of breaking
	edible = {{"snack",2,"",0,4},{"flask",10,"",0,2}} --name, heal amount, other effect, other amount, fixed heal

	-- unused items:
	-- {3,"gavel",117,0,0}
	-- {3,"jokki",114,0,0}
	-- {3,"exomis",102,0,0}
	-- {3,"estoc",115,0,0}
	-- {3,"quest",100,0,0}
	-- {1,"wailer",36,0,0,12}
	-- {1,"homunc",39,0,0,12,0}
	-- {1,"groza",40,0,0,12}

  function dig_tunnels()
    -- set x and y for straight tunnels
    local x = flr(rnd(room_width-2))+2
    local y = flr(rnd(room_height-2))+2
    -- identify areas where tunnels are needed
    for i=1, #grid do
      for j=1, #grid[i] do
        -- horizontal
        local horizontal_count = 0
        if j==2 then
          if grid[i][j-1]!=0 then horizontal_count += 1 end
          if grid[i][j+1]!=0 then horizontal_count += 1 end
        end
        if grid[i][j] == 0 and j==2 and horizontal_count==cell_width-1 then
          for x=1,level_width-2 do
            -- add wall tiles north
            if mget((x-1)+((j-1)),(y-2)+((i-1)*room_height))==2 then
              mset((x-1)+((j-1)),(y-2)+((i-1)*room_height),1)
            end
            -- add wall tiles south
            if mget((x-1)+((j-1)),(y)+((i-1)*room_height))==2 then
              mset((x-1)+((j-1)),(y)+((i-1)*room_height),1)
            end
            -- delete everything
            mset((x-1)+((j-1)),(y-1)+((i-1)*room_height),0)
          end
        end

        -- vertical
        local vertical_count = 0
        if i==2 then
          if grid[i-1][j]!=0 then vertical_count += 1 end
          if grid[i+1][j]!=0 then vertical_count += 1 end
        end
        if grid[i][j] == 0 and i==2 and vertical_count==cell_height-1 then
          for y=1,level_height-2 do
            -- add wall tiles west
            if mget((x-2)+((j-1)*room_width),(y-1)+(i-1))==2 then
              mset((x-2)+((j-1)*room_width),(y-1)+(i-1),1)
            end
            -- add wall tiles east
            if mget(x+((j-1)*room_width),(y-1)+(i-1))==2 then
              mset(x+((j-1)*room_width),(y-1)+(i-1),1)
            end
            -- delete everything
            mset((x-1)+((j-1)*room_width),(y-1)+((i-1)),0)
          end
        end
      end
    end
  end

  function populate_tiles()
    local difficulty_scale = flr(room / 5)
    if difficulty_scale > 5 then
      difficulty_scale = 5
    end
    level_difficulty = flr(rnd(6)) + difficulty_scale
		-- level_difficulty = 1

    if level_difficulty >= 8 then
      add(log,{player_steps,"you get a bad feeling."})
    end

    entities = {}

		-- every floor do
		place_entity_randomly({1,"slime",32,0,0,12})

		-- every floor randomly place
		for i=1,flr(level_difficulty/2)+1+flr(rnd(2)) do
			if rnd(1) > .75 then
				place_entity_randomly({1,"slime",32,0,0,12})
			else
				place_entity_randomly({1,"rat",33,0,0,12})
			end
		end

		-- specific enemies per floor
		if level_difficulty <= 2 then
			if rnd(1) > .75 then
				place_entity_randomly({3,"snack",99,0,0})
			end
		end
		if level_difficulty > 2 and level_difficulty <= 4 then
			for j=1,3 do
				if rnd(1) > .25 then
					place_entity_randomly({1,"dancer",37,0,0,32})
				end
			end
			for j=1,2 do
				if rnd(1) > .25 then
					place_entity_randomly({1,"flame",38,0,0,64,""})
				end
			end
		elseif level_difficulty <= 6 then
			for j=1,2 do
				if rnd(1) > .25 then
					place_entity_randomly({1,"flame",38,0,0,64,""})
				end
			end
			for j=1,1 do
				if rnd(1) > .5 then
					place_entity_randomly({1,"homunc",39,0,0,48,0})
				end
			end
			for j=1,2 do
				if rnd(1) > .5 then
					place_entity_randomly({1,"dancer",37,0,0,32})
				end
			end
		else
			for j=1,2 do
				if rnd(1) > .25 then
					place_entity_randomly({1,"flame",38,0,0,64,""})
				end
			end
			for j=1,2 do
				if rnd(1) > .5 then
					place_entity_randomly({1,"homunc",39,0,0,48,0})
				end
			end
			for j=1,2 do
				if rnd(1) > .25 then
					place_entity_randomly({1,"dancer",37,0,0,48})
				end
			end
		end

		-- lategame items
		if level_difficulty >= 6 then
			if rnd(1) > .9 then
				place_entity_randomly({3,"gavel",117,0,0})
			end
			if rnd(1) > .9 then
				place_entity_randomly({3,"jokki",114,0,0})
			end
		end
		if level_difficulty >= 8 then
			if rnd(1) > .8 then
				place_entity_randomly({3,"sword+3",115,0,0})
			end
			if rnd(1) > .8 then
				place_entity_randomly({3,"exomis",114,0,0})
			end
			for j=1,2 do
				if rnd(1) > .5 then
					place_entity_randomly({3,"snack",99,0,0})
				end
			end
			if rnd(1) > .5 then
				place_entity_randomly({3,"flask",101,0,0})
			end
		end

		if room == 24 then
			place_entity_randomly({1,"groza",40,0,0,56})
		end
  end

  function get_tile_count(tile)
    local count = 0
    for x=1,level_width do
  		for y=1,level_height do
  			if mget(level_width-x,level_height-y) == tile then
          count += 1
        end
  		end
  	end
    return count
  end

  function remove_tiles(tile)
    for x=1,level_width do
      for y=1,level_height do
        if mget(x,y) == tile then
          mset(x,y,0)
          return false
        end
      end
    end
  end

  function place_entity_randomly(entity)
    -- places the entity randomly on the grid
    -- give an entity dict, but set x and y to arbitrary values
    local rnd_x = flr(rnd(level_width-1))+1
    local rnd_y = flr(rnd(level_height-1))+1
    while contains_impassible_tiles(mget(rnd_x, rnd_y), true) or entity_there(rnd_x*8, rnd_y*8, true) do
      rnd_x = flr(rnd(level_width))
      rnd_y = flr(rnd(level_height))
    end
    add(entities,{entity[1],entity[2],entity[3],rnd_x*8,rnd_y*8,entity[6]})
  end

  function place_tile_randomly(tile)
    local rnd_x = flr(rnd(level_width-1))+1
    local rnd_y = flr(rnd(level_height-1))+1
    while mget(rnd_x, rnd_y) != 0 do
      rnd_x = flr(rnd(level_width))
      rnd_y = flr(rnd(level_height))
    end
    mset(rnd_x, rnd_y, tile)
  end

  function tile_rooms()
  	for x=1,level_width do
  		for y=1,level_height do
  			mset(x-1,y-1,2)
  		end
  	end

    for i=1, #grid do
      for j=1, #grid[i] do
        -- get width
        if grid[i][j] != 0 then
          for y=1,room_height do
            for x=1,room_width do
              -- add wall tiles
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),1)
              -- add inner tiles (to be fleshed out)
              if x!=1 and x!=room_width and y!=1 and y!=room_height then
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),0)
                -- make stairs
  							if grid[i][j] == 2 then
                  -- make stairs everywhere you can
  								mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),15)
  							end
              end
              -- fix up neighbouring rooms
              -- west and east
              if x==1 and j>1 and grid[i][j-1]!=0 and y!=1 and y!=room_height and mget((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height)) != 15 then
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),0)
              elseif x==room_width and j<#grid[i] and grid[i][j+1]!=0 and y!=1 and y!=room_height then
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),0)
              end
              -- north and south
              if y==1 and i>1 and grid[i-1][j]!=0 and x!=1 and x!=room_width and mget((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height)) != 15 then
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),0)
              elseif y==room_height and i<#grid and grid[i+1][j]!=0 and x!=1 and x!=room_width then
                mset((x-1)+((j-1)*room_width),(y-1)+((i-1)*room_height),0)
              end
            end
          end
        end
      end
    end
  end

  function generate_level()
    -- tweakable parameters
    level_width = 12
    level_height = 12
    cell_width = 3
    cell_height = 3
    room_width = level_width / cell_width
    room_height = level_height / cell_height
    room_count = 6

    -- generate grid based on cell width and height
    grid = {}
    for y=1,cell_height do
      add(grid,{})
      for x=1,cell_width do
        add(grid[y],0)
      end
    end

    -- generate tile grid for fov and decoration
    level_grid = {}
    for y=1,level_height do
      add(level_grid,{})
      for x=1,level_width do
        add(level_grid[y],flr(rnd(2)))
      end
    end

    -- dynamically add to the grid showing the rooms
    local current_rooms = 1
    -- add player's current room
    local player_room_x = flr(player_x / room_width / 8) + 1
    local player_room_y = flr(player_y / room_height / 8) + 1
    grid[player_room_y][player_room_x] = 1

    while current_rooms < room_count do
      local y = flr(rnd(cell_height)) + 1
      local x = flr(rnd(cell_width)) + 1
      if grid[y][x] != 1 then
        -- ...make it a room
        grid[y][x] = 1

        -- count the rooms to make sure it's not over the total count
        current_rooms = 0
        for rows in all(grid) do
          for room in all(rows) do
            if room != 0 then
              current_rooms += 1
            end
            if current_rooms == room_count then
              grid[y][x] = 2
            end
          end
        end
      end
    end

    tile_rooms()
    dig_tunnels()

    -- remove extra stairs
    while get_tile_count(15) > 1 do
      remove_tiles(15)
    end
    if get_tile_count(15) < 1 then
      place_tile_randomly(15)
    end
		if rnd(1) > .75 then
			place_tile_randomly(42)
		end
		if room == 24 then
			-- final floor, remove exits
			remove_tiles(15)
			remove_tiles(42)
			add(log,{player_steps,"this should be the place."})
		end

  	populate_tiles()
  	room += 1
  end

	function point_is_in_grid(x,y,grid)
		for e in all(grid) do
			if e[1] == x and e[2] == y then
				return e[3]
			end
		end
		return false
	end

	function update_enemy_movement_grid()
		enemy_movement_grid = {}

		add(enemy_movement_grid,{player_x/8, player_y/8, 0})
		for i=0,2 do
			for e in all(enemy_movement_grid) do
				if e[3] == i then
					local xto = e[1]-1
					local yto = e[2]
					if not contains_impassible_tiles(mget(xto,yto),true) and not point_is_in_grid(xto,yto,enemy_movement_grid) then
						add(enemy_movement_grid,{xto,yto,i+1})
					end
					local xto = e[1]+1
					local yto = e[2]
					if not contains_impassible_tiles(mget(xto,yto),true) and not point_is_in_grid(xto,yto,enemy_movement_grid) then
						add(enemy_movement_grid,{xto,yto,i+1})
					end
					local xto = e[1]
					local yto = e[2]-1
					if not contains_impassible_tiles(mget(xto,yto),true) and not point_is_in_grid(xto,yto,enemy_movement_grid) then
						add(enemy_movement_grid,{xto,yto,i+1})
					end
					local xto = e[1]
					local yto = e[2]+1
					if not contains_impassible_tiles(mget(xto,yto),true) and not point_is_in_grid(xto,yto,enemy_movement_grid) then
						add(enemy_movement_grid,{xto,yto,i+1})
					end
				end
			end
		end
	end

	function debug_enemy_movement_grid()
		-- for i in all(enemy_movement_grid) do
		-- 	print(i[3],i[1]*8,i[2]*8,7)
		-- end
	end

	function new_input()
		local list_of_input = {btnp(0),btnp(1),btnp(2),btnp(3),btnp(4),btnp(5)}
		return list_of_input
	end

  function update_fov()
    fov_grid = level_grid
    local player_grid_x = player_x / 8
    local player_grid_y = player_y / 8

    player_fov={
      {player_grid_x-1,player_grid_y-2,12},
      {player_grid_x,player_grid_y-2,12},
      {player_grid_x+1,player_grid_y-2,12},
      {player_grid_x-2,player_grid_y-1,12},
      {player_grid_x-1,player_grid_y-1,10},
      {player_grid_x,player_grid_y-1,10},
      {player_grid_x+1,player_grid_y-1,10},
      {player_grid_x+2,player_grid_y-1,12},
      {player_grid_x-2,player_grid_y,12},
      {player_grid_x-1,player_grid_y,10},
      {player_grid_x,player_grid_y,10},
      {player_grid_x+1,player_grid_y,10},
      {player_grid_x+2,player_grid_y,12},
      {player_grid_x-2,player_grid_y+1,12},
      {player_grid_x-1,player_grid_y+1,10},
      {player_grid_x,player_grid_y+1,10},
      {player_grid_x+1,player_grid_y+1,10},
      {player_grid_x+2,player_grid_y+1,12},
      {player_grid_x-1,player_grid_y+2,12},
      {player_grid_x,player_grid_y+2,12},
      {player_grid_x+1,player_grid_y+2,12},
    }

    local tile_count=1
    for tile in all(player_fov) do
      if contains_impassible_tiles(mget(tile[1],tile[2]),false) or mget(tile[1],tile[2]) == 42 then
        del(player_fov, tile)
      end
      tile_count+=1
    end
  end

  function draw_fov()
    update_fov()
    for i in all(player_fov) do
      if level_grid[i[1]] != nil and level_grid[i[2]] != nil then
        spr(i[3]+level_grid[i[1]][i[2]],i[1]*8,i[2]*8)
      else
        spr(i[3],i[1]*8,i[2]*8)
      end
    end
		debug_enemy_movement_grid()
  end

  function is_visible(x, y)
    -- gets visibility by x and y
    x = flr(x/8)
    y = flr(y/8)
    for i in all(player_fov) do
      if i[1] == x and i[2] == y then
        return true
      end
    end
    -- return true -- debug only, todo: set to false
  end

	function map_draw()
    if room == 0 then
      mapdraw(0,0,0,0,128,148)
      return
    end
    draw_fov()
    -- custom control over what is lit
    -- it's lit fam
    for i=0,level_height do
      for j=0,level_width do
        if mget(i,j) == 15 and is_visible(i*8, j*8) then
          -- mapdraw(i,j,i*8,j*8,1,1)
          mapdraw(i-1,j-1,(i-1)*8,(j-1)*8,3,3)
        elseif mget(i,j) != 15 and is_visible(i*8, j*8) then
          mapdraw(i-1,j-1,(i-1)*8,(j-1)*8,3,3)
        elseif mget(i,j) == 2 then
          mapdraw(i,j,i*8,j*8,1,1)
        end
      end
    end
	end

	function change_room(relative)
		dpal={0,1,1, 2,1,13,13, 4,4,9,3, 13,1,13,14}
		for i=0,40 do
			for j=1,15 do
				col = j
				for k=1,((i+(j%5))/4) do
					col=dpal[col]
				end
				pal(j,col,1)
			end
			for l=1,2 do
				flip()
			end
		end
		generate_level()
	end

	function game_draw()
		print(log[count(log)-1][2],4,camera_y+107,1)
		print(log[count(log)-1][2],4,camera_y+106,5)
		print(log[count(log)][2],4,camera_y+115,1)
		print(log[count(log)][2],4,camera_y+114,13)
		spr(63,camera_x+98,camera_y+0)
		print(player_health .. "/" .. player_max_health,camera_x+108,camera_y+1,7)
		for i=1,6 do
			spr(player_inventory[i][3],camera_x+98,camera_y+(i*8))
			if player_inventory[i][2] != "" then
				if i <= 3 then
					print(player_inventory[i][2],camera_x+108,camera_y+1+(i*8),7)
				else
					print(player_inventory[i][2],camera_x+108,camera_y+1+(i*8),13)
				end
			else
				print("none",camera_x+108,camera_y+1+(i*8),1)
			end
		end
		print(player_effects[1],camera_x+100,camera_y+1+(7*8),1)
		print(player_effects[2],camera_x+100,camera_y+1+(8*8),1)
		print("flr " .. room,camera_x+100,camera_y+2+(9*8),1)
		print("flr " .. room,camera_x+100,camera_y+1+(9*8),13)
		print("str " .. player_stats.str,camera_x+100,camera_y+2+(10*8),1)
		print("str " .. player_stats.str,camera_x+100,camera_y+1+(10*8),13)
		print("def " .. player_stats.def,camera_x+100,camera_y+2+(11*8),1)
		print("def " .. player_stats.def,camera_x+100,camera_y+1+(11*8),13)
		-- print("poison",camera_x+100,camera_y+1+(11*8),3)
		if show_menu then
			menu()
		end
		if show_prompt then
			if game_won == true then
				win_prompt()
				return
			end
			prompt()
		end
		if input[5] and not show_prompt then
			show_menu = true
		end
	end

	function menu()
		if menu_selection == nil then
			menu_selection = 0
		end
		if btnp(2) then
			if menu_selection == 0 then menu_selection = 5 else menu_selection -= 1 end
		end
		if btnp(3) then
			if menu_selection == 5 then menu_selection = 0 else menu_selection += 1 end
		end
		if input[5] then
			input[5] = false
			if player_inventory[menu_selection+1][2] != "" then
				show_menu = false
				show_prompt = true
			end
		end
		if btnp(5) then
			show_menu = false
			show_prompt = false
		end
		rect(camera_x+98,camera_y+7+(8*menu_selection),camera_x+127,camera_y+15+(8*menu_selection),7)
	end

	function prompt()
		rect(camera_x+16,camera_y+32,camera_x+111,camera_y+79,13)
		rectfill(camera_x+17,camera_y+33,camera_x+110,camera_y+78,0)
		line(camera_x+16,camera_y+80,camera_x+111,camera_y+80,1)
		print("what do you want to",camera_x+24,camera_y+40,7)
		print("do with the "..player_inventory[menu_selection+1][2].."?",camera_x+24,camera_y+48,7)
		for i=1,5 do
			if i <= 3 then
				print(player_actions[i][1]..player_actions[i][2],camera_x+(24+(i-1)*28),camera_y+58,7)
			else
				print(player_actions[i][1]..player_actions[i][2],camera_x+(24+(i-4)*28),camera_y+66,7)
			end
		end
		if btnp(0) then
			for i=1,5 do
				if player_actions[i][1] == cursor then
					player_actions[i][1] = ""
					if i==1 then
						player_actions[5][1] = cursor
						break
					else
						player_actions[i-1][1] = cursor
						break
					end
				end
			end
		end
		if btnp(1) then
			for i=1,5 do
				if player_actions[i][1] == cursor then
					player_actions[i][1] = ""
					if i==5 then
						player_actions[1][1] = cursor
						break
					else
						player_actions[i+1][1] = cursor
						break
					end
				end
			end
		end
		if input[5] then
			for i=1,5 do
				if player_actions[i][1] == cursor then
					if i == 1 then
						wear_selected_item()
						show_prompt = false
					end
					if i == 2 then
						throw_selected_item()
            sfx(4)
						show_prompt = false
					end
					if i == 3 then
						eat_selected_item()
            sfx(4)
						show_prompt = false
					end
					if i == 4 then
						drop_selected_item()
            sfx(4)
						show_prompt = false
					end
					if i == 5 then
						show_menu = false
						show_prompt = false
					end
				end
			end
		end
		if btnp(5) then
			show_menu = true
			show_prompt = false
		end
	end

	function win_prompt()
		rect(camera_x+16,camera_y+32,camera_x+111,camera_y+79,13)
		rectfill(camera_x+17,camera_y+33,camera_x+110,camera_y+78,0)
		line(camera_x+16,camera_y+80,camera_x+111,camera_y+80,1)
		print("congratulations, the",camera_x+24,camera_y+40,7)
		print("challenge is over.",camera_x+24,camera_y+48,7)
		print("steps taken: "..player_steps,camera_x+24,camera_y+58,7)
		print("kills: "..player_kills,camera_x+24,camera_y+66,7)
	end

	function entity_there(x_check,y_check,count_player)
		local result = false
		for i=1,count(entities) do
			if entities[i][4] == x_check and entities[i][5] == y_check then
				if entities[i][1] != 2 and entities[i][1] != 3 then
					result = true
				end
			else
				if count_player or count_player == nil then
					if player_x == x_check and player_y == y_check then
						result = true
					end
				end
			end
		end
		return result
	end

	function item_there(x_check,y_check)
		for i=1,count(entities) do
			if entities[i][4] == x_check and entities[i][5] == y_check and entities[i][1] == 3 then
				return entities[i]
			end
		end
		return false
	end

	function stash_item(item)
		for i=4,6 do
			if player_inventory[i][2] == "" then
				add(log,{player_steps,"you stash the "..item[2].."."})
				player_inventory[i][2] = item[2]
				player_inventory[i][3] = item[3]
				del(entities,item)
				return
			end
		end
		add(log,{player_steps,"no room in your pockets."})
	end

	function wear_selected_item()
		local can_wear = false
		for item in all(wearable) do
			if item[1] == player_inventory[menu_selection+1][2] then
				can_wear = true
				if item[2] == menu_selection+1 then
					add(log,{player_steps,"you're already wearing this."})
					break
				end
				if player_inventory[item[2]][2] != "" then
					add(log,{player_steps,"take off your "..player_inventory[item[2]][2].." first."})
					break
				end
				-- move it to the correct slot
				player_inventory[item[2]][3] = player_inventory[menu_selection+1][3]
				player_inventory[item[2]][2] = player_inventory[menu_selection+1][2]
				player_inventory[menu_selection+1][3] = 62
				player_inventory[menu_selection+1][2] = ""
				add(log,{player_steps,"you put on the "..item[1].."."})
        sfx(4)
				-- apply stats and status effects
				if item[3] != nil and item[3] != 0 then
					player_stats.def = item[3]
					if item[5] != nil and item[5] != "" then
						player_effects[1] = item[5]
					end
				end
				if item[4] != nil and item[4] != 0 then
					player_stats.str = item[4]
					if item[5] != nil and item[5] != "" then
						player_effects[2] = item[5]
					end
				end
				break
			else
				add(log,{player_steps,"you can't find a way to wear"})
				add(log,{player_steps,"the "..player_inventory[menu_selection+1][2].."."})
			end
		end
	end

	function throw_selected_item()
		local distance = -flr(-rnd(3)) + 1
		local direction = flr(player_image/2) -- 0 = left, 1 = right, 2 = up, 3 = down
		local to_x = 0
		local to_y = 0
		add(log,{player_steps,"you throw the "..player_inventory[menu_selection+1][2].."."})
		for d=1,distance do
			-- get player direction
			local direction = flr(player_image/2) -- 0 = left, 1 = right, 2 = up, 3 = down
			if direction <= 1 then
				to_x = player_x + 8*d*sgn(direction-1)
				to_y = player_y
				to = mget(player_x/8 + d*sgn(direction-1), player_y/8)
			else
				to_x = player_x
				to_y = player_y + 8*d*sgn(direction-3)
				to = mget(player_x/8, player_y/8 + d*sgn(direction-3))
			end
			-- if contains entity then hit that entity
			if entity_there(to_x,to_y,false) then
				for e in all(entities) do
					if e[4] == to_x and e[5] == to_y then
						for item in all(breakable) do
							if player_inventory[menu_selection+1][2] == item[1] and rnd(1) < item[4] then
								add(log,{player_steps,"the "..player_inventory[menu_selection+1][2].." breaks!"})
								add(entities,{
									2,
									"liquid",
									74+flr(rnd(4)),
									e[4],
									e[5]
								})
								player_inventory[menu_selection+1][2] = ""
								if menu_selection > 2 then
									-- todo: debug this
									player_inventory[menu_selection+1][3] = 62
								end
								return
							elseif e[1] == 1 then
								local roll = nil
								for i in all(wearable) do
									if i[1] == player_inventory[menu_selection+1][2] then
										if i[4] != nil then
											roll = flr(rnd(i[4]))
										end
									end
								end
								if roll == nil then
									roll = flr(rnd(3))
								end
								add(log,{player_steps,"the "..player_inventory[menu_selection+1][2].." hits the "..e[2].." for "..roll})
								add(log,{player_steps,"damage!"})
								e[6] -= roll
								if e[6] <= 0 then
									entity_die(e)
									d = d+1
								end
							end
						end
					end
				end
				distance = d-1
				player_step(0,0)
				break
			end
			-- if contains a wall, bounce off or break
			if contains_impassible_tiles(to,true) then
				add(log,{player_steps,"the "..player_inventory[menu_selection+1][2].." bounces and falls."})
				distance = d-1
				player_step(0,0)
				break
			end
		end
		if direction <= 1 then
			add(entities,{
				3,
				player_inventory[menu_selection+1][2],
				player_inventory[menu_selection+1][3],
				player_x+(distance*8)*sgn(direction-1),
				player_y}
			)
		else
			add(entities,{
				3,
				player_inventory[menu_selection+1][2],
				player_inventory[menu_selection+1][3],
				player_x,
				player_y+(distance*8)*sgn(direction-3)}
			)
		end
		player_inventory[menu_selection+1][2] = ""
		if menu_selection > 2 then
			player_inventory[menu_selection+1][3] = 62
		end
		if menu_selection + 1 == 1 then
			player_stats.str = 0
			for e in all(entities) do
				if player_effects[2] == "sticky" and e[7] != nil and e[7] == "stuck" then
					del(e,e[7])
				end
			end
			player_effects[2] = ""
		end
		if menu_selection + 1 == 2 then
			player_stats.def = 0
			player_effects[1] = ""
		end
	end

	function eat_selected_item()
		local can_eat = false
		for i=1,count(edible) do
			if player_inventory[menu_selection+1][2] == edible[i][1] then
				can_eat = true
				-- eat the cake, anime
				player_heal(edible[i][1],edible[i][2],edible[i][5])
				-- remove the item from inventory
				player_inventory[menu_selection+1][2] = ""
				if menu_selection > 2 then
					player_inventory[menu_selection+1][3] = 62
				end
			end
		end

		if can_eat == false then
			add(log,{player_steps,"eating this would be difficult."})
		end
	end

	function drop_selected_item()
		add(log,{player_steps,"you drop the "..player_inventory[menu_selection+1][2].."."})
		add(entities,{
			3,
			player_inventory[menu_selection+1][2],
			player_inventory[menu_selection+1][3],
			player_x,
			player_y})
		player_inventory[menu_selection+1][2] = ""
		-- update stats if it's an equipped item
		if menu_selection + 1 == 1 then
			player_stats.str = 0
			for e in all(entities) do
				if player_effects[2] == "sticky" and e[7] != nil and e[7] == "stuck" then
					del(e,e[7])
				end
			end
			player_effects[2] = ""
		end
		if menu_selection + 1 == 2 then
			player_stats.def = 0
			player_effects[1] = ""
		end
		if menu_selection > 2 then
			player_inventory[menu_selection+1][3] = 62
		end
	end

	function entity_draw()
		for e in all(entities) do
			if e[1] == 2 or e[1] == 3 then
        if room == 0 and not entity_there(e[4],e[5],false) then
          spr(e[3], e[4], e[5])
        end
				if not entity_there(e[4],e[5],false) and is_visible(e[4],e[5]) then
          -- static objects (items and splatter)
					spr(e[3], e[4], e[5])
				end
			else
        -- living objects
        if room == 0 then
          spr(e[3]+((player_steps % 2)*16), e[4], e[5])
        end
        if is_visible(e[4],e[5]) then
		      spr(e[3]+((player_steps % 2)*16), e[4], e[5])
        end
			end
		end
	end

	function entity_update()
		for e in all(entities) do
			-- movement patterns
			if e[2] == "slime" then -- check if they're stuck or frozen or something
				roll = rnd(2)-1
				if roll >= 0.67 then
					etox = (sgn(rnd(2)-1)*8)/8
					etoy = 0
				else
					if roll <= -0.67 then
						etox = 0
						etoy = (sgn(rnd(2)-1)*8)/8
					else
						etox = 0
						etoy = 0
					end
				end
			end
			if e[2] == "rat" then
				roll = rnd(2)-1
				if roll >= 0.2 then
					etox = (sgn(rnd(2)-1)*8)/8
					etoy = 0
				else
					if roll <= -0.2 then
						etox = 0
						etoy = (sgn(rnd(2)-1)*8)/8
					else
						etox = 0
						etoy = 0
					end
				end
			end
			if e[2] == "dancer" then
				-- have to reset etox and etoy otherwise they'll use the global values
				-- use tiles for when you're detected, then follow the direction of the player
				etox = 0
				etoy = 0
				local tox = (e[4]/8)+1
				local toy = (e[5]/8)
				if point_is_in_grid(tox,toy,player_fov) then
					etox = 1
				end
				local tox = (e[4]/8)-1
				local toy = (e[5]/8)
				if point_is_in_grid(tox,toy,player_fov) then
					etox = -1
				end
				local tox = (e[4]/8)
				local toy = (e[5]/8)+1
				if point_is_in_grid(tox,toy,player_fov) then
					etoy = 1
				end
				local tox = (e[4]/8)
				local toy = (e[5]/8)-1
				if point_is_in_grid(tox,toy,player_fov) then
					etoy = -1
				end
				if ((e[4]/8)-(player_x/8))^2 + ((e[5]/8)-(player_y/8))^2 == 1 then
					if rnd(1) > .25 and e[1] == 1 then
						player_take_damage(e,4+flr(room/5))
						screen_shake(1,2)
						etox = 0
						etoy = 0
					end
				end
			end
			if e[2] == "homunc" then
				etox = 0
				etoy = 0
				local priority = ""
				local current_min = 100

				local tox = (e[4]/8)+1
				local toy = (e[5]/8)
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						priority = "right"
						current_min = check
					end
				end

				local tox = (e[4]/8)-1
				local toy = (e[5]/8)
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						current_min = check
						priority = "left"
					end
				end

				local tox = (e[4]/8)
				local toy = (e[5]/8)+1
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						current_min = check
						priority = "down"
					end
				end

				local tox = (e[4]/8)
				local toy = (e[5]/8)-1
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						priority = "up"
					end
				end

				if rnd(1) > .75 then -- slower than the player
					etox = 0
					etoy = 0
				elseif ((e[4]/8)-(player_x/8))^2 + ((e[5]/8)-(player_y/8))^2 == 1 and e[1] == 1 then -- attack!
					priority = ""
					etox = 0
					etoy = 0
					add(log,{player_steps,"the "..e[2].."flails at you."})
					player_take_damage(e,5+flr(room/5))
					screen_shake(1,2)
				else
					if priority == "up" then
						etoy = -1
					elseif priority == "down" then
						etoy = 1
					elseif priority == "left" then
						etox = -1
					elseif priority == "right" then
						etox = 1
					end
				end
			end
			if e[2] == "groza" then
				etox = 0
				etoy = 0
				local priority = ""
				local current_min = 100

				local tox = (e[4]/8)+1
				local toy = (e[5]/8)
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						priority = "right"
						current_min = check
					end
				end

				local tox = (e[4]/8)-1
				local toy = (e[5]/8)
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						current_min = check
						priority = "left"
					end
				end

				local tox = (e[4]/8)
				local toy = (e[5]/8)+1
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						current_min = check
						priority = "down"
					end
				end

				local tox = (e[4]/8)
				local toy = (e[5]/8)-1
				local check = point_is_in_grid(tox,toy,enemy_movement_grid)
				if check then
					if check < current_min then
						priority = "up"
					end
				end

				if rnd(1) > .75 then -- slower than the player
					etox = 0
					etoy = 0

					if ((e[4]/8)-(player_x/8))^2 + ((e[5]/8)-(player_y/8))^2 <= 2 and e[1] == 1 then -- attack!
						priority = ""
						etox = 0
						etoy = 0
						player_take_damage(e,5+flr(room/5))
						screen_shake(1,2)
					end
				else
					if priority == "up" then
						etoy = -1
					elseif priority == "down" then
						etoy = 1
					elseif priority == "left" then
						etox = -1
					elseif priority == "right" then
						etox = 1
					end
				end
			end
			if e[2] == "flame" then
				etox = 0
				etoy = 0

				if e[7] == "" or e[7] == nil then
					e[7] = flr(rnd(4))
				end
				if e[7] == 0 then
					etox = 1
				end
				if e[7] == 1 then
					etoy = 1
				end
				if e[7] == 2 then
					etox = -1
				end
				if e[7] == 3 then
					etoy = -1
				end
				local to = mget((e[4]/8)+etox,(e[5]/8)+etoy)
				if contains_impassible_tiles(to,true) or entity_there(e[4]+etox*8,e[5]+etoy*8,true) then
					if player_x == e[4]+etox*8 and player_y == e[5]+etoy*8 and e[1] == 1 then
						etox = 0
						etoy = 0
						player_take_damage(e,14)
						screen_shake(10,15)
					else
						etox = 0
						etoy = 0
						if e[7] != nil then
							e[7] += 1
							if e[7] > 3 then e[7] = 0 end
						end
					end
				end
				if e[1] == 1 then
					e[4] += etox*8
					e[5] += etoy*8
				end
			end

			-- do something based on what tile is there
			if e[1] == 1 and e[7] == nil or e[7] == "" then
				to = mget((e[4]/8)+etox,(e[5]/8)+etoy)
				if contains_impassible_tiles(to,true)==false then
					if not entity_there(e[4]+etox*8,e[5]+etoy*8) then
						e[4] += etox*8
						e[5] += etoy*8
					end
					if player_x == e[4]+etox*8 and player_y == e[5]+etoy*8 then
						if e[2] == "slime" then
							add(log,{player_steps,"the "..e[2].." smiles at you."})
						end
						if e[2] == "rat" then
							player_take_damage(e,2)
							screen_shake(1,2)
						end
					end
				end
			end
		end
	end

	function entity_die(e)
		add(log,{player_steps,"the "..e[2].." dies."})
		player_kills += 1
		e[1] = 2
		if e[2] == "groza" then
			e[3] = 5
		else
			e[3] = 70+flr(rnd(4))
		end
		if rnd(1) > 0.85 then
			-- add a big blood splatter
			local direction = flr(player_image/2)
			if direction <= 1 then
				add(entities,{
					2,
					"blood",
					72+flr(rnd(2)),
					e[4]+8*sgn(direction-1),
					e[5]
				})
			else
				add(entities,{
					2,
					"blood",
					72+flr(rnd(2)),
					e[4],
					e[5]+8*sgn(direction-3)
				})
			end
		end

		entity_drops(e)
	end

	function entity_drops(e)
		-- add special enemy drops here
		-- if it's a rat, drop a snack 25% of the time
		if e[2] == "rat" and rnd(1) > 0.75 then
			add(entities,{3,"snack",99,e[4],e[5]})
		end
		if e[2] == "dancer" and rnd(1) > 0.25 then
			val = rnd(1)
			if val >= (2/3) then
				add(entities,{3,"flask",101,e[4],e[5]})
			elseif val >= (1/3) then
				add(entities,{3,"estoc",115,e[4],e[5]})
			else
				add(entities,{3,"poncho",113,e[4],e[5]})
			end
		end
		if e[2] == "homunc" and rnd(1) > 0.6 then
			local val = 1+flr(rnd(3))
			if val == 1 then
				add(entities,{3,"jokki",114,e[4],e[5]})
			elseif val == 2 then
				add(entities,{3,"exomis",102,e[4],e[5]})
			elseif val == 3 then
				add(entities,{3,"gavel",117,e[4],e[5]})
			end
		end
		if e[2] == "groza" then
			add(entities,{0,"quest",88,e[4],e[5]})
		end
	end

	function player_update()
		player_move()
		player_draw()
	end

	function player_attack(e,dice)
		add(log,{player_steps,"you swing at the "..e[2].."..."})
		local roll = flr(rnd(dice+1))
		roll = flr(roll * 1+(player_stats.str / 2))
		if roll == 0 then
			add(log,{player_steps,"...but you miss!"})
		else
			if player_effects[2] == "bash" then
				if rnd(1) > .5 then
					add(log,{player_steps,"you bash the "..e[2].."!"})
					roll = roll + 2
					local relative_x = e[4] - player_x
					local relative_y = e[5] - player_y
					if not entity_there(e[4]+relative_x, e[5]+relative_y, false) and not contains_impassible_tiles(mget((e[4]+relative_x)/8, (e[5]+relative_y)/8), true) then
						e[4] += relative_x
						e[5] += relative_y
					end
				end
			end
			add(log,{player_steps,"you hit for "..roll.." damage!"})
		end
		e[6] -= roll
		if e[6] <= 0 then
			entity_die(e)
		elseif player_effects[2] == "sticky" then
			for e in all(entities) do
				if player_effects[2] == "sticky" and e[7] != nil and e[7] == "stuck" then
					del(e,e[7])
				end
			end
			if e[2] == "slime" or e[2] == "rat" and rnd(1) > .75 then
				e[7] = "stuck"
				add(log,{player_steps,"you stick the "..e[2].."."})
			end
		end
	end

	function player_take_damage(source,dice)
		local roll = flr(rnd(dice+1))
		if source != "fall" and source[2] != nil then
			-- factor in def for most sources
			-- change to the entity name, if applicable
			-- parry on certain rolls
			source_name = source[2]
			add(log,{player_steps,player_stats.def.." damage blocked!"})
			roll -= player_stats.def
			if roll < 0 then roll = 0 end
			if rnd(1) > .75 and player_effects[2] == "parry" then
				roll = roll * 2 -- parry modifier
				add(log,{player_steps,"you parry for "..roll.." damage!"})
				source[6] -= roll
				if source[6] <= 0 then
					entity_die(source)
				end
				return
			end
		else
			if source != nil then
				source_name = source
			else
				source_name = "something"
			end
		end
		add(log,{player_steps,"the "..source_name.." does "..roll.." damage!"})
		player_health -= roll
		if player_health <= 0 then
			player_health = 0
			player_die()
		end
	end

	function player_heal(source,dice,fixed_amount)
		if fixed_amount == nil then fixed_amount = 0 end
		local roll = flr(1+rnd(dice)) + fixed_amount
		add(log,{player_steps,"the "..source.." heals "..roll.."hp!"})
		player_health += roll
		if player_health > player_max_health then
			player_health = player_max_health
		end
	end

	function screen_shake(radius,length)
		local old_camera_x = camera_x
		local old_camera_y = camera_y
		for i=0,length do
			cls()
			map_draw()
			entity_draw()
			player_draw()
			game_draw()
			camera_x += rnd(radius*2)-radius
			camera_y += rnd(radius*2)-radius
			camera(camera_x,camera_y)
			flip()
			camera_x = old_camera_x
			camera_y = old_camera_y
		end
	end

	function player_die()
		sfx(0)
		for i=0,60 do
			cls()
			map_draw()
			entity_draw()
			game_draw()
			spr(16,player_x,player_y)
			camera(camera_x,camera_y)
			flip()
		end
		change_room(0)
		run()
	end

	function contains_impassible_tiles(to,for_enemies)
		local impassible = false
		local tiles = {}
		if for_enemies == false or for_enemies == nil then
			tiles = {60,61,1,2,3}
		else
			tiles = {60,61,86,42,15,1,2,3}
		end
		for t=1,count(tiles) do
			if to == tiles[t] then impassible=true end
		end
		return impassible
	end

	function player_fall()
		for i=0,30 do
			cls()
			map_draw()
			entity_draw()
			game_draw()
			spr(17+flr(i/10),player_x,player_y)
			flip()
		end
		change_room(1)
		_draw()
		player_step(0,0)
		screen_shake(2,5)
		player_take_damage("fall",6)
		sfx(0)
	end

	function player_step(x,y,img)
		player_x_previous = player_x
		player_y_previous = player_y

		for e in all(entities) do
			-- for items
			if e[4] == player_x+x and e[5] == player_y+y and e[1] == 3 then
				add(log,{player_steps,"there is a "..e[2].." laying here."})
			end
			-- for status effects for enemies
			if e[1] == 1 then
				if e[7] != nil and e[7] == "stuck" then
					if contains_impassible_tiles(mget((e[4]+x)/8,(e[5]+y)/8),true) or entity_there(e[4]+x,e[5]+y,true) then
						del(e,e[7])
						add(log,{player_steps,"the "..e[2].." pops off."})
					else
						if not entity_there(e[4]+x*2,e[5]+y*2,false) and not contains_impassible_tiles(mget((player_x+x)/8,(player_y+y)/8),false) then -- check if the player is blocked on the other side
							e[4] += x
							e[5] += y
						end
					end
				end
			end
			-- for interactive objects
			if e[4] == player_x+x and e[5] == player_y+y and e[1] != 2 and e[1] != 3 then
				if e[2] == "block" then
					to = mget((player_x+(x*2))/8,(player_y+(y*2))/8)
					if contains_impassible_tiles(to,true) == false then
						if not entity_there(player_x+(x*2),player_y+(y*2)) then
							e[4] = player_x+(x*2)
							e[5] = player_y+(y*2)
							player_x += x
							player_y += y
							add(log,{player_steps,"you move the "..e[2].."."})
							sfx(0)
						else
							return
						end
					else
						return
					end
				end
				if e[2] == "fire" then
					add(log,{player_steps,"the fire seems to radiate an"})
					add(log,{player_steps,"abnormal amount of energy..."})
					sfx(1)
				end
				if e[2] == "quest" then
					game_won = true
					show_prompt = true
				end
        if e[2] == "wizard" and room == 0 then
          sfx(5)
					if e[7] == 6 then
						add(log,{player_steps,"does that make sense?"})
						add(log,{player_steps,""})
					end
					if e[7] == 5 then
						add(log,{player_steps,"oh! you'll be stuck here until"})
						add(log,{player_steps,"you find a nondescript object."})
						e[7] += 1
					end
					if e[7] == 4 then
						add(log,{player_steps,"what else..."})
						add(log,{player_steps,""})
						e[7] += 1
					end
					if e[7] == 3 then
						add(log,{player_steps,"hmm..."})
						add(log,{player_steps,""})
						e[7] += 1
					end
					if e[7] == 2 then
						add(log,{player_steps,"look out for dancers, who play with"})
						add(log,{player_steps,"their victims, and little men."})
						e[7] += 1
					end
					if e[7] == 1 then
						add(log,{player_steps,"make your way through the void and"})
						add(log,{player_steps,"find the other side."})
						e[7] += 1
					end
					if e[7] == 0 then
          	add(log,{player_steps,"what's the trouble?"})
						add(log,{player_steps,""})
						e[7] += 1
					end
        end
				if e[1] == 1 then
					player_attack(e,6)
					sfx(0)
				end
				player_steps += 1
				player_image = img+(player_steps%2)
				entity_update()
				return
			end
		end

		to = mget((player_x+x)/8,(player_y+y)/8)
		if contains_impassible_tiles(to) == false then
			if to == 42 then
				player_x += x
				player_y += y
				sfx(3)
				add(log,{player_steps,"you fall down the hole!"})
				player_fall()
				return
			end
			if to == 96 then
				mset((player_x+x)/8,(player_y+y)/8,97)
				sfx(4,0)
			end
			if to == 15 or to == 87 then
				change_room(1)
			end
			player_x += x
			player_y += y
			player_steps += 1
			if img != nil then
				player_image = img+(player_steps%2)
			end
			if x != 0 or y != 0 then
				sfx(1+(player_steps%2))
			end
			entity_update()
		end

		update_enemy_movement_grid()
	end

	function player_move()
		if show_menu or show_prompt then player_can_move = false else player_can_move = true end
		if player_can_move then
			if btnp(0) then
				player_step(-8,0,0)
			end
			if btnp(1) then
				player_step(8,0,2)
			end
			if btnp(2) then
				player_step(0,-8,4)
			end
			if btnp(3) then
				player_step(0,8,6)
			end
			if btnp(5) then
				local item = item_there(player_x,player_y)
					if item then
						stash_item(item)
					else
            -- wait
						add(log,{player_steps,"you look around..."})
					end
				player_step(0,0)
			end
		end
	end

	function player_draw()
		if player_is_visible then
			spr(player_image+128,player_x,player_y)
		end
	end

  -- run once
  -- generate_level()
	enemy_movement_grid = {}
end

function _update()
end

function _draw()
	pal()
	pal(6,0)
	cls()
	input = new_input()
	map_draw()
	entity_draw()
	player_update()
	game_draw()
	camera(camera_x,camera_y)
end























__gfx__
00000000d111111501001000000000000000000000000000dddddddd0000000077777777e222222e050010131100111000030000010010000100100006000060
000000000511115000000000000000000008000000000000dddddddd00000000777777770e2222e0033013001110551000000000110101000000000064666646
00700700005d5d0000000000000000000088000000000000dddddddd000000007777777700eeee00103003030110510000000000100010010000000064444456
0007700000d5dd0000000001000000000888888000000000dddddddd000000007777777700eeee00501500150001001100003003000000010000000165666626
00077000005ddd0000100000000000000888888000000000dddddddd000000007777777700eeee00330311001010055503000000000100000010000062222116
0070070000dddc0000000000000000000088000000000000dddddddd000000007777777700eee700011105101001015500000000001001000000000062666616
000000000100001000000010000000000008000000000000dddddddd000000007777777702000020131033010011100100000030000010100000001061111666
000000001000000100000000000000000000000000000000dddddddd000000007777777720000002100530130055010000000000000001000000000061666666
06444600164446000000000000000000000000000000000000000000000300000000011000011001000000010011000000030000050010130500301300009000
644464600644646000066000000060000000000000000000000000000300003000105551000111000055001110111000030000300330130003301b000008a800
6466f6606466f66600622666000626000000000000000000000000000300000001000551000015000055d01100151000030000001030030310b003030089a900
26fff6cff6fff66f0624414600624600000000000000000000000000000300031510001001100055000dd000000100110003000350150015501300130d8aa8d0
226ccc60fc6666cf0611116000611600000000000000000000000000000000030550100011510055d01100150500011100000003330311003b1b3100d209822d
26ccccc666cccc6664611600006160000000000000000000000000000300000010011101111000005511111100000510030000000111051001330510d202202d
0f6cc6c606cccc606661616000060000000000000000000000000000000003001100510100005001111110111005500000000300131033011310b3011d2002e1
0026c66006c666000066066000000000000000000000000000000000000300001101000001000011100001001105500100030000100530131005303301deee10
0006600006460000e222222e061dd16006288600628826000006860000000000061116001110511000000000115d000000666660000004f00066660000080000
006bb600646666006e2222e661d666166126626022866460006896000006600061666160011011100000000001500000061ddd1600044f400624446000098000
06bbb3606455116066eeee66616fff1606144260626ff4600689a860006226666160616000000101000000000111055001c666c1004f4f0006222260008a9800
63bbb6366555564666eeee66065ddd606165556006966696089a7a80062441460616116000dd0110000000000111d5500dcccccd00ffff00062442600d9aa8d0
63b633366156455666eeee66616dd566062656466268696f08977a800611116061606616055d1110000000000110dd000d1ccc1d00fff44f06244226d208982d
633333361656155666eee76661d6616f61646160f6622626089779806461160061606161055011100000000010100000011dcd1100fffff406242442d202202d
633333366065652662666626f61555660611161660626646668998666661616016166166000005100000000001110110061cdc16000fff40065ffff51e2002d1
0633336000066660266666626611116061666066064600600666666000660660661111600000d511000000000115011100666660000000000066666001eede10
0000000000642600e222222e061dd160006882600062882600696000000000000061116010055011001000011100001021111112d11111150ddddddd00000000
00000000064666006e2222e661d666160626621606466822006a9600000660000616661600055001110111111005000002111120051111500d00000d00880880
066666606155516066eeee66616fff1606244160064ff6260697a960666226000616061601500000111111550000011100222200005d5d000d11111d08788888
63bbbb361555551666eeee66065ddd60065556166966696009a77a906414426006116160111000505100110d550015110022220000d5dd000d11111d08888888
3bbbb6336555564666eeee66616dd56064656260f696862609a77a90061111606166061611001000000dd0005500011000222200005ddd000d11111d00888880
3bb633330656455666eee766f6d66166061646166262266f09a77a90006116461616061600015100110d5500005100000022220000dddc000d11111d00088800
3333333306561556626666266615556f6161116064662606669aa966061616666616616100011101110055000011100001000010010000100ddddddd00008000
63333336061665262666666206111166660666160600646006666660066066000611116600001100100000001001100010000001100000010000000000000000
00000000000000100000000000000000111111201101111000000000000000000000000000000000000000000000000000000000000000000000000000000000
02221110000001010000011008882221011112121110122000200200000020000200000000200000009009000000900009000000009000000000000000000000
00011111100010110000012000022222201121220111028022220000000222200000220000000200900900000000099000009900000009000000000000000000
00200011110001011001102000800122220112122002208002222220002022020000022000222000009999900090000900000990009090000000000000000000
02011001101000111100020008022001212001222210080000222200022202200000000002222200009999000900009000000000090999000000000000000000
02100000010100011111100008201110121210022222200002222222002220000200000200022220099000090000900009000009000990900000000000000000
01100000001000000111222002210111012111101222888000022000022202000000000000000000000990000900090000000000000000000000000000000000
00000000000000000000000001111011001111110000000000000000000000000000000000000200000000000000000000000000000009000000000000000000
00000000111111501101111000000000222222502202255000000010015dd5108266662800000000000000000000000000000000000000000000000000000000
0ddd5551011115151110155009994452022225252220544000000101101111012628866200000000000000000000000000000000000000000000000000000000
0005555550115155011105d000044455502252550255049010001011010000106628286600000000000000000000000000000000000000000000000000000000
00d0015555011515500550d0009005554502252450044090110001010000000066662e6600000000000000000000000000000000000000000000000000000000
0d0550055150015555100d0009044005525002445550090010100011000000006662e66600000000000000000000000000000000000000000000000000000000
0d501110151510055555500009405520252520045544400001010001000000006666666600000000000000000000000000000000000000000000000000000000
05510111015111101555ddd004450222025222202544999000100000000000002662e66200000000000000000000000000000000000000000000000000000000
01111011001111110000000005522022002222220000000000000000000000008266662800000000000000000000000000000000000000000000000000000000
0ddddddd00000000006cc60000666600826666280066660000666660000662868266662800000000000000000000000000000000000000000000000000000000
0d00000d0555555506dbcd60061421602628866206182160061ddd16066288682628866200000000000000000000000000000000000000000000000000000000
0d1ddddd0500000561cc771606466260662828660686326061c000c1626868686628286600000000000000000000000000000000000000000000000000000000
0d10000d051555556ccc77c60624426066662e66062882606c77777c2868682866662e6600000000000000000000000000000000000000000000000000000000
0d1d1d1d051000056d7cccd6624225266662e666628223266cd777dc886828866662e66600000000000000000000000000000000000000000000000000000000
0d1d1d1d05151515061221606244d4566666666662889836611ccc11682286626666666600000000000000000000000000000000000000000000000000000000
0ddddddc05151515006446006124d2162662e6626128921606177716688662882662e66200000000000000000000000000000000000000000000000000000000
01111111055555550066660006115160826666280611316000666660826288268266662800000000000000000000000000000000000000000000000000000000
006666600066666000666660666000000006d6006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
061ddd1606122216061eee166dd6000000d067606ddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000
61c666c161d666d1618666816d776660060767606dd7760000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dcccccd62ddddd262881882067771266d6672606d7d760000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d1ccc1d621ddd126218e81200677460067724160677426000000000000000000000000000000000000000000000000000000000000000000000000000000000
611dcd116114d4116139993100614216006661410066241600000000000000000000000000000000000000000000000000000000000000000000000000000000
061cdc16061d4d160618e81600626126000006140000614600000000000000000000000000000000000000000000000000000000000000000000000000000000
00666660006666600066666000660666000000660000066600000000000000000000000000000000000000000000000000000000000000000000000000000000
06444600064446000064446000644460064446000064446006444600006444600000000000000000000000000000000000000000000000000000000000000000
64644460646444600644464606444646064444600644446006446460064644600000000000000000000000000000000000000000000000000000000000000000
06f6646006f6646006466f6006466f6064444460064444466466f660066f66460000000000000000000000000000000000000000000000000000000000000000
06fff66006fff600066fff60006fff60064446600664446006fff660066fff600000000000000000000000000000000000000000000000000000000000000000
66666c6006666c6006c6666606c666606c666cc66cc666c66c6666c66c6666c60000000000000000000000000000000000000000000000000000000000000000
f6ccc6f006c6f6600f6ccc6f066f6c60f6cccc6ff6cccc6ff6cccc6ff6cccc6f0000000000000000000000000000000000000000000000000000000000000000
66ccc66006ccc600066ccc66006ccc6066cccc6666cccc6666cccc6666cccc660000000000000000000000000000000000000000000000000000000000000000
0066c6006c666c60006c660006c666c606c6660000666c6006c6660000666c600000000000000000000000000000000000000000000000000000000000000000
__map__
3d3d3d3d3d3d3d3d3d3d3d3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d415741414141414141413d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d1d18180d0e05050c1c1d3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d0b0b5051515152051c1c3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d0b18404141414205050c3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d180d43444444450505053d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d390b404141414205050e3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d0d394344444445050e0d3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d1b0d40414141420e0d393d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d391b50515151520d05393d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d2a0b2b0e050e0d391b183d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d3d3d3d3d3d3d3d3d3d3d0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001c6001c600010100b0201d03018010090501c0100d0401d0100d040200100c0301c010130300c0101c0300b0301f0101201021610120101c0001d000236001d0001a0002560025600256002560025600
000100001a640136100b6101d60012600116000f6000e6000c6000a60007600056000360002600016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000463003620016100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00001557014570135601256011560105500f5500d5400b5400853005520035100151001600016000160001600065000350001500105000f5000d5000b5000850006500065000150001500015000000000000
00010000212401b220152101160011600130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000000d7101171015720197200e1200e1200e1200a1100b11008110081100c110127100f7100d710107100e1100c1100a1100a7100771004710011000110001100000000000000000000000000000000
