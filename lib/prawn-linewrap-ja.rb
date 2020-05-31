require "prawn"

module Prawn
  module Text
    module Formatted
      class LineWrap
        alias_method :original_initialize_line, :initialize_line

        def initialize_line(options)
          original_initialize_line(options)
          @disable_wrap_by_char = true
        end

        def end_of_the_line_reached(segment)
          update_line_status_based_on_last_output
          unless @line_contains_more_than_one_word
            wrap_by_char(segment)
          end
          @line_full = true
        end
        
        def self.or_rgexp( chars )
          s = chars.chars.map{ |e| Regexp.escape(e) }.join
          /[#{s}]/
        end

        # 行頭禁則文字
        PROHIBIT_LINE_BREAK_BEFORE = or_rgexp(
          ')}]' +
          '’”）〕］｝〉》」』】｠〙〗»〟' +  # 終わり括弧類（cl-02）
          '‐〜゠–' + # ハイフン類（cl-03）
          '！？‼⁇⁈⁉' + # 区切り約物（cl-04）
          '・：；' + # 中点類（cl-05）
          '。．' + # 句点類（cl-06）
          '、，' + # 読点類（cl-07）
          'ヽヾゝゞ々〻' + # 繰返し記号（cl-09）
          'ー' + # 長音記号（cl-10）
          'ぁぃぅぇぉァィゥェォっゃゅょゎゕゖッャュョヮヵヶㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿㇷ゚' + # 小書きの仮名（cl-11）
          '）〕］' # 割注終わり括弧類（cl-29）
        )
        # 行末禁則文字
        PROHIBIT_LINE_BREAK_AFTER = or_rgexp(
          '({[' +
          '‘“（〔［｛〈《「『【｟〘〖«〝' + # 始め括弧類（cl-01）
          '（〔［' # 割注始め括弧類（cl-28）
        )
        # 分離禁止文字
        PROHIBIT_DIVIDE = '—…‥〳〴〵' # 分離禁止文字（cl-08）

        ALNUM=/[a-zA-Z0-9_@]/

        def tokenize(fragment)
          fragment.size.times.with_object([""]) do |ix,s|
            cur = fragment[ix]
            if s.last.empty?
              s.last << cur
            elsif PROHIBIT_LINE_BREAK_AFTER===s.last[-1]
              s.last << cur
            elsif PROHIBIT_LINE_BREAK_BEFORE===cur
              s.last << cur
            elsif ALNUM===s.last[-1]
              if ALNUM===cur
                s.last << cur
              else
                s.push cur
              end
            else
              s.push cur
            end
          end
        end
      end
    end
  end
end
