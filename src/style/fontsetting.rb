Prawn::Svg::Font::GENERIC_CSS_FONT_MAPPING.merge!(
  'sans-serif' => 'GenShinGothic-P-Normal',
  'serif' => 'GenShinGothic-P-Normal',
  'monospace' => 'Ricty Regular'
)

$stderr.puts( Prawn::Svg::Font::GENERIC_CSS_FONT_MAPPING.inspect )