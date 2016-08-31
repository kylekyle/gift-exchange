# encoding: utf-8
Shoes.app resizable: false, title: 'Gift Exchange' do
	start { Shoes.APPS.each {|app| app.close if app.name == 'Shoes'} }

	background File.join(Dir.getwd,"stripe.png")
	background rgb(255, 255, 255, 0.95)

	set_window_icon_path File.join(Dir.getwd,"icon.png")
	banner 'Gift Exchange', stroke: maroon, margin: 25, align: 'center'

	groups = Hash.new {|h,k| h[k] = []}

	exchange = proc do
		result = []

		array = groups.values.flat_map do |group|
			group.map do |gifter|
				[gifter, (groups.values - [group]).flatten]
			end
		end

		recurse = proc do |gifter, result=[]|
			if result.size == array.size
				result
			else
				gifter, recipients = array.assoc gifter
				eligibles = recipients - result

				if eligibles.empty?
					nil
				else
					recipient = eligibles.shuffle.min_by do |eligible| 
						(array.assoc(eligible).last - result).size
					end

					result << recipient
					recurse.call recipient, result
				end
			end
		end

		gifter, recipients = array.shuffle.min_by(&:size)
		recurse.call gifter
	end

	slide = proc do |operation, comparison, action|
		proc do 
			action.call unless action.nil?
			target = @page.left.send(operation, width)

			animation = animate 24 do
				if @page.left.send(comparison, target)
					animation.stop
					@page.move target, @page.top
				else
					@page.move @page.left.send(operation, 60), @page.top
				end
			end
		end
	end

	back = proc do |&action|
		click = slide.curry[:+][:>=][action]
		image(File.join(Dir.getwd,"arrow.png"), top: 125, height: 50, left: -60, click: click).rotate 180
	end

	forward = proc do |&action|
		click = slide.curry[:-][:<=][action]
		image(File.join(Dir.getwd,"arrow.png"), top: 125, height: 50, right: -60, click: click)
	end

	@page = flow width: width*4 do 
		stack width: width, margin_left: 35, margin_right: 75 do
			para 'A good gift exchange should be random, but there are some rules you should follow: ', size: 16
			para "    • Nobody should gift themselves\n",
			"    • Nobody should gift their partner\n",
			"    • Nobody should gift the person gifting them\n", 
			"    • Nobody should know who is gifting who\n", 
			"    • Everybody should have fun", size: 16
			para "Ready to get started? Click the arrow on the right.", size: 16
			para 'Created by ', link('kylekyle', click: 'http://github.com/kylekyle'), ' in ', link('Ruby Shoes', click: 'http://shoesrb.com'), attach: app.slot, variant: 'smallcaps', top: app.slot.height - 40, size: 10, align: 'center'
			forward.call 
		end

		stack width: width, margin_left: 75, margin_right: 75 do 		
			para "Add gifters, one name per line, in the box below. You need at least three gifters to move on."

			gifters = edit_box width: '100%', height: 300

			button = forward.call do 
				groups.clear
				@gifters.clear

				gifters.text.strip.each_line.map(&:strip).uniq.each do |name|
					@gifters.append do 
						slot = flow width: '45%', margin: 10 do 
							bg = background rgb(0,0,0,1)
							groups[bg.fill] << name

							border black
							para strong(name), margin_top: 10, align: 'center'

							click do
								bg.remove
								groups[bg.fill].delete name
								groups.delete bg.fill if groups[bg.fill].empty?

								slot.prepend { bg = background(@group || rgb(0,0,0,1))}
								groups[bg.fill] << name

								exchange.call.nil? ? @forward.hide : @forward.show
							end
						end
					end
				end
			end

			back.call 
			button.hide

			change = proc do |box| 
				names = box.text.strip.each_line.map(&:strip).uniq
				names.size > 2 ? button.show : button.hide
			end

			gifters.style change: change
		end

		stack width: width, margin_left: 75, margin_right: 75 do
			para "Now it's time to create exchange groups. Gifters can only exchange with people outside their group. For example, if you don't want couples to exchange with eachother, then create a group for each couple. "
			para "Each group has its own color. Click a color below, then click the names of the gifters you want to group under that color. Deselect all colors and click a name to remove it from its group."
			para strong("Some groupings will make an exchange impossible (such as everyone in the same group). You can only continue when the grouping allows for an exchange.")

			flow margin_top: 10, margin_bottom: 15 do 
				swatches = []
				[blue, brown, green, orange, purple, yellow, aqua, blueviolet, pink, salmon, palevioletred, thistle, yellowgreen, palegoldenrod, white].map do |color|
					flow(width: 30, height: 30) do 
						swatches << (swatch = rect fill: color, width: 25, height: 25)
						click do 
							if swatch.style[:stroke] == hotpink
								@group = rgb(0,0,0,1)
								swatch.style(stroke: black, strokewidth: 1)
							else
								@group = swatch.style[:fill]
								swatch.style(stroke: hotpink, strokewidth: 2)
							end
							(swatches-[swatch]).each {|s| s.style(stroke: black, strokewidth: 1)}
						end
					end
				end
			end

			back.call 
			@gifters = flow margin_left: 20

			@forward = forward.call do 
				@masks = []
				@computed = exchange.call
				@computed << @computed.first

				@computed.each_cons(2) do |gifter,reciever|
					@exchange.append do 
						flow width: '45%', margin: 15 do 
							para strong(gifter), align: 'center', margin_top: 20
							@masks << background(rgb(255,255,255))
							@masks << para(strong('?'), align: 'center', margin_top: 20)
							border black
						end
						flow width: '10%', height: 75, margin_top: 20 do 
							para strong("⇨"), size: 24, align: 'center'
						end
						flow width: '45%', margin: 15 do 
							para strong(reciever), align: 'center', margin_top: 20
							@masks << background(rgb(255,255,255))
							@masks << para(strong('?'), align: 'center', margin_top: 20)
							border black
						end
					end
				end
			end
		end

		stack width: width, margin_left: 75, margin_right: 75 do
			back.call { @exchange.clear }

			para "A random exchange has been computed. If you don't want to know who's gifting who, you can click the ", strong("Generate Text Files"), " button. That will generate a text file for every gifter that contains the person they are gifting. Email that to the gifter."
			para "You can also click ", strong("Show Names"), " to see who is gifting who. You can always get a new random exchange by leaving this page and coming back."

			button 'Generate Text Files', width: '100%', margin_top: 10 do 
				folder = ask_open_folder
				@computed.each_cons(2) do |gifter,reciever|
					File.write File.join(folder,"#{gifter}.txt"), reciever
				end
				alert "Saved #{@computed.size} files to #{folder}" 
			end

			button('Show Names', width: '100%') { @masks.map &:remove }

			@exchange = flow margin_bottom: 50, margin_top: 20
		end
	end
end