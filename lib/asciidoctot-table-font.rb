require "asciidoctor-pdf"
require "pry"
require_relative "asciidoctor-nabehelper"

module Asciidoctor
  module PDF
    class Converter
      def convert_table node
        add_dest_for_block node if node.id
        # TODO: we could skip a lot of the logic below when num_rows == 0
        num_rows = node.attr 'rowcount'
        num_cols = node.columns.size
        table_header_size = false
        theme = @theme

        tbl_bg_color = resolve_theme_color :table_background_color
        # QUESTION should we fallback to page background color? (which is never transparent)
        #tbl_bg_color = resolve_theme_color :table_background_color, @page_bg_color
        # ...and if so, should we try to be helpful and use @page_bg_color for tables nested in blocks?
        #unless tbl_bg_color
        #  tbl_bg_color = @page_bg_color unless [:section, :document].include? node.parent.context
        #end

        # NOTE: emulate table bg color by using it as a fallback value for each element
        head_bg_color = resolve_theme_color :table_head_background_color, tbl_bg_color
        foot_bg_color = resolve_theme_color :table_foot_background_color, tbl_bg_color
        body_bg_color = resolve_theme_color :table_body_background_color, tbl_bg_color
        body_stripe_bg_color = resolve_theme_color :table_body_stripe_background_color, tbl_bg_color

        base_header_cell_data = nil
        header_cell_line_metrics = nil

        table_data = []
        theme_font :table do
          head_rows = node.rows[:head]
          body_rows = node.rows[:body]
          #if (hrows = node.attr 'hrows', false, nil) && (shift_rows = hrows.to_i - head_rows.size) > 0
          #  head_rows = head_rows.dup
          #  body_rows = body_rows.dup
          #  shift_rows.times { head_rows << body_rows.shift unless body_rows.empty? }
          #end
          theme_font :table_head do
            table_header_size = head_rows.size
            head_font_info = font_info
            head_line_metrics = calc_line_metrics theme.base_line_height
            head_cell_padding = theme.table_head_cell_padding || theme.table_cell_padding
            head_cell_padding = ::Array === head_cell_padding && head_cell_padding.size == 4 ? head_cell_padding.dup : (inflate_padding head_cell_padding)
            head_cell_padding[0] += head_line_metrics.padding_top
            head_cell_padding[2] += head_line_metrics.padding_bottom
            # QUESTION why doesn't text transform inherit from table?
            head_transform = resolve_text_transform :table_head_text_transform, nil
            base_cell_data = {
              inline_format: [normalize: true],
              background_color: head_bg_color,
              text_color: @font_color,
              size: head_font_info[:size],
              font: head_font_info[:family],
              font_style: head_font_info[:style],
              kerning: default_kerning?,
              padding: head_cell_padding,
              leading: head_line_metrics.leading,
              # TODO: patch prawn-table to pass through final_gap option
              #final_gap: head_line_metrics.final_gap,
            }
            head_rows.each do |row|
              table_data << (row.map do |cell|
                cell_text = head_transform ? (transform_text cell.text.strip, head_transform) : cell.text.strip
                cell_text = hyphenate_text cell_text, @hyphenator if defined? @hyphenator
                base_cell_data.merge \
                  content: cell_text,
                  colspan: cell.colspan || 1,
                  align: (cell.attr 'halign', nil, false).to_sym,
                  valign: (val = cell.attr 'valign', nil, false) == 'middle' ? :center : val.to_sym
              end)
            end
          end unless head_rows.empty?

          base_cell_data = {
            font: (body_font_info = font_info)[:family],
            font_style: body_font_info[:style],
            size: body_font_info[:size],
            kerning: default_kerning?,
            text_color: @font_color,
          }
          body_cell_line_metrics = calc_line_metrics theme.base_line_height
          (body_rows + node.rows[:foot]).each do |row|
            table_data << (row.map do |cell|
              cell_data = base_cell_data.merge \
                colspan: cell.colspan || 1,
                rowspan: cell.rowspan || 1,
                align: (cell.attr 'halign', nil, false).to_sym,
                valign: (val = cell.attr 'valign', nil, false) == 'middle' ? :center : val.to_sym
              cell_line_metrics = body_cell_line_metrics
              case cell.style
              when :emphasis
                cell_data[:font_style] = :italic
              when :strong
                cell_data[:font_style] = :bold
              when :header
                unless base_header_cell_data
                  theme_font :table_head do
                    theme_font :table_header_cell do
                      header_cell_font_info = font_info
                      base_header_cell_data = {
                        text_color: @font_color,
                        font: header_cell_font_info[:family],
                        size: header_cell_font_info[:size],
                        font_style: header_cell_font_info[:style],
                        text_transform: @text_transform,
                      }
                      header_cell_line_metrics = calc_line_metrics theme.base_line_height
                    end
                  end
                  if (val = resolve_theme_color :table_header_cell_background_color, head_bg_color)
                    base_header_cell_data[:background_color] = val
                  end
                end
                cell_data.update base_header_cell_data
                cell_transform = cell_data.delete :text_transform
                cell_line_metrics = header_cell_line_metrics
              when :monospaced
                cell_data.delete :font_style
                theme_font :literal do
                  mono_cell_font_info = font_info
                  cell_data[:font] = mono_cell_font_info[:family]
                  cell_data[:size] = mono_cell_font_info[:size]
                  cell_data[:text_color] = @font_color
                  cell_line_metrics = calc_line_metrics theme.base_line_height
                end
              when :literal
                # NOTE: we want the raw AsciiDoc in this case
                cell_data[:content] = guard_indentation cell.instance_variable_get :@text
                # NOTE: the absence of the inline_format option implies it's disabled
                cell_data.delete :font_style
                # QUESTION should we use literal_font_*, code_font_*, or introduce another category?
                theme_font :code do
                  literal_cell_font_info = font_info
                  cell_data[:font] = literal_cell_font_info[:family]
                  cell_data[:size] = literal_cell_font_info[:size]
                  cell_data[:text_color] = @font_color
                  cell_line_metrics = calc_line_metrics theme.base_line_height
                end
              when :verse
                cell_data[:content] = guard_indentation cell.text
                cell_data[:inline_format] = true
                cell_data.delete :font_style
              when :asciidoc
                cell_data.delete :kerning
                cell_data.delete :font_style
                cell_line_metrics = nil
                asciidoc_cell = ::Prawn::Table::Cell::AsciiDoc.new self,
                    (cell_data.merge content: cell.inner_document, font_style: (val = theme.table_font_style) ? val.to_sym : nil, padding: theme.table_cell_padding)
                cell_data = { content: asciidoc_cell }
              end
              if cell_line_metrics
                cell_padding = ::Array === (cell_padding = theme.table_cell_padding) && cell_padding.size == 4 ?
                  cell_padding.dup : (inflate_padding cell_padding)
                cell_padding[0] += cell_line_metrics.padding_top
                cell_padding[2] += cell_line_metrics.padding_bottom
                cell_data[:leading] = cell_line_metrics.leading
                # TODO: patch prawn-table to pass through final_gap option
                #cell_data[:final_gap] = cell_line_metrics.final_gap
                cell_data[:padding] = cell_padding
              end
              unless cell_data.key? :content
                cell_text = cell.text.strip
                cell_text = transform_text cell_text, cell_transform if cell_transform
                cell_text = hyphenate_text cell_text, @hyphenator if defined? @hyphenator
                cell_text = cell_text.gsub CjkLineBreakRx, ZeroWidthSpace if @cjk_line_breaks
                if cell_text.include? LF
                  # NOTE: effectively the same as calling cell.content (should we use that instead?)
                  # FIXME: hard breaks not quite the same result as separate paragraphs; need custom cell impl here
                  cell_data[:content] = (cell_text.split BlankLineRx).map {|l| l.tr_s WhitespaceChars, ' ' }.join DoubleLF
                  cell_data[:inline_format] = true
                else
                  cell_data[:content] = cell_text
                  cell_data[:inline_format] = [normalize: true]
                end
              end
              if node.document.attr? 'cellbgcolor'
                if (cell_bg_color = node.document.attr 'cellbgcolor') == 'transparent'
                  cell_data[:background_color] = body_bg_color
                elsif (cell_bg_color.start_with? '#') && (HexColorRx.match? cell_bg_color)
                  cell_data[:background_color] = cell_bg_color.slice 1, cell_bg_color.length
                end
              end
              cell_data
            end)
          end
        end

        # NOTE: Prawn aborts if table data is empty, so ensure there's at least one row
        if table_data.empty?
          logger.warn message_with_context 'no rows found in table', source_location: node.source_location
          table_data << ::Array.new([node.columns.size, 1].max) { { content: '' } }
        end

        border_width = {}
        table_border_color = theme.table_border_color || theme.table_grid_color || theme.base_border_color
        table_border_style = (theme.table_border_style || :solid).to_sym
        table_border_width = theme.table_border_width
        if table_header_size
          head_border_bottom_color = theme.table_head_border_bottom_color || table_border_color
          head_border_bottom_style = (theme.table_head_border_bottom_style || table_border_style).to_sym
          head_border_bottom_width = theme.table_head_border_bottom_width || table_border_width
        end
        [:top, :bottom, :left, :right].each {|edge| border_width[edge] = table_border_width }
        table_grid_color = theme.table_grid_color || table_border_color
        table_grid_style = (theme.table_grid_style || table_border_style).to_sym
        table_grid_width = theme.table_grid_width || theme.table_border_width
        [:cols, :rows].each {|edge| border_width[edge] = table_grid_width }

        case (grid = node.attr 'grid', 'all', 'table-grid')
        when 'all'
          # keep inner borders
        when 'cols'
          border_width[:rows] = 0
        when 'rows'
          border_width[:cols] = 0
        else # none
          border_width[:rows] = border_width[:cols] = 0
        end

        case (frame = node.attr 'frame', 'all', 'table-frame')
        when 'all'
          # keep outer borders
        when 'topbot', 'ends'
          border_width[:left] = border_width[:right] = 0
        when 'sides'
          border_width[:top] = border_width[:bottom] = 0
        else # none
          border_width[:top] = border_width[:right] = border_width[:bottom] = border_width[:left] = 0
        end

        if node.option? 'autowidth'
          table_width = (node.attr? 'width', nil, false) ? bounds.width * ((node.attr 'tablepcwidth') / 100.0) :
              (((node.has_role? 'stretch') || (node.has_role? 'spread')) ? bounds.width : nil)
          column_widths = []
        else
          table_width = bounds.width * ((node.attr 'tablepcwidth') / 100.0)
          column_widths = node.columns.map {|col| ((col.attr 'colpcwidth') * table_width) / 100.0 }
          # NOTE: until Asciidoctor 1.5.4, colpcwidth values didn't always add up to 100%; use last column to compensate
          unless column_widths.empty? || (width_delta = table_width - column_widths.sum) == 0
            column_widths[-1] += width_delta
          end
        end

        if ((alignment = node.attr 'align', nil, false) && (BlockAlignmentNames.include? alignment)) ||
            (alignment = (node.roles & BlockAlignmentNames)[-1])
          alignment = alignment.to_sym
        else
          alignment = (theme.table_align || :left).to_sym
        end

        caption_side = (theme.table_caption_side || :top).to_sym
        caption_max_width = theme.table_caption_max_width || 'fit-content'

        table_settings = {
          header: table_header_size,
          # NOTE: position is handled by this method
          position: :left,
          cell_style: {
            # NOTE: the border color and style of the outer frame is set later
            border_color: table_grid_color,
            border_lines: [table_grid_style],
            # NOTE: the border width is set later
            border_width: 0,
          },
          width: table_width,
          column_widths: column_widths,
        }

        # QUESTION should we support nth; should we support sequence of roles?
        case node.attr 'stripes', nil, 'table-stripes'
        when 'all'
          table_settings[:row_colors] = [body_stripe_bg_color]
        when 'even'
          table_settings[:row_colors] = [body_bg_color, body_stripe_bg_color]
        when 'odd'
          table_settings[:row_colors] = [body_stripe_bg_color, body_bg_color]
        else # none
          table_settings[:row_colors] = [body_bg_color]
        end

        theme_margin :block, :top

        left_padding = right_padding = nil
        table table_data, table_settings do
          # NOTE: call width to capture resolved table width
          table_width = width
          @pdf.layout_table_caption node, alignment, table_width, caption_max_width if node.title? && caption_side == :top
          # NOTE align using padding instead of bounding_box as prawn-table does
          # using a bounding_box across pages mangles the margin box of subsequent pages
          if alignment != :left && table_width != (this_bounds = @pdf.bounds).width
            if alignment == :center
              left_padding = right_padding = (this_bounds.width - width) * 0.5
              this_bounds.add_left_padding left_padding
              this_bounds.add_right_padding right_padding
            else # :right
              left_padding = this_bounds.width - width
              this_bounds.add_left_padding left_padding
            end
          end
          if grid == 'none' && frame == 'none'
            rows(table_header_size).tap do |r|
              r.border_bottom_color = head_border_bottom_color
              r.border_bottom_line = head_border_bottom_style
              r.border_bottom_width = head_border_bottom_width
            end if table_header_size
          else
            # apply the grid setting first across all cells
            cells.border_width = [border_width[:rows], border_width[:cols], border_width[:rows], border_width[:cols]]

            if table_header_size
              rows(table_header_size - 1).tap do |r|
                r.border_bottom_color = head_border_bottom_color
                r.border_bottom_line = head_border_bottom_style
                r.border_bottom_width = head_border_bottom_width
              end
              rows(table_header_size).tap do |r|
                r.border_top_color = head_border_bottom_color
                r.border_top_line = head_border_bottom_style
                r.border_top_width = head_border_bottom_width
              end if num_rows > table_header_size
            end

            # top edge of table
            rows(0).tap do |r|
              r.border_top_color, r.border_top_line, r.border_top_width = table_border_color, table_border_style, border_width[:top]
            end
            # right edge of table
            columns(num_cols - 1).tap do |r|
              r.border_right_color, r.border_right_line, r.border_right_width = table_border_color, table_border_style, border_width[:right]
            end
            # bottom edge of table
            rows(num_rows - 1).tap do |r|
              r.border_bottom_color, r.border_bottom_line, r.border_bottom_width = table_border_color, table_border_style, border_width[:bottom]
            end
            # left edge of table
            columns(0).tap do |r|
              r.border_left_color, r.border_left_line, r.border_left_width = table_border_color, table_border_style, border_width[:left]
            end
          end

          # QUESTION should cell padding be configurable for foot row cells?
          unless node.rows[:foot].empty?
            foot_row = row num_rows.pred
            foot_row.background_color = foot_bg_color
            # FIXME: find a way to do this when defining the cells
            foot_row.text_color = theme.table_foot_font_color if theme.table_foot_font_color
            foot_row.size = theme.table_foot_font_size if theme.table_foot_font_size
            foot_row.font = theme.table_foot_font_family if theme.table_foot_font_family
            foot_row.font_style = theme.table_foot_font_style.to_sym if theme.table_foot_font_style
            # HACK: we should do this transformation when creating the cell
            #if (foot_transform = resolve_text_transform :table_foot_text_transform, nil)
            #  foot_row.each {|c| c.content = (transform_text c.content, foot_transform) if c.content }
            #end
          end
        end
        if left_padding
          bounds.subtract_left_padding left_padding
          bounds.subtract_right_padding right_padding if right_padding
        end
        layout_table_caption node, alignment, table_width, caption_max_width, caption_side if node.title? && caption_side == :bottom
        theme_margin :block, :bottom
      end
    end
  end
end
