require 'psd/layer/info/blend_clipping_elements'
require 'psd/layer/info/blend_interior_elements'
require 'psd/layer/info/fill_opacity'
require 'psd/layer/info/gradient_fill'
require 'psd/layer/info/layer_group'
require 'psd/layer/info/layer_id'
require 'psd/layer/info/layer_name_source'
require 'psd/layer/info/layer_section_divider'
require 'psd/layer/info/legacy_typetool'
require 'psd/layer/info/locked'
require 'psd/layer/info/metadata_setting'
require 'psd/layer/info/object_effects'
require 'psd/layer/info/pattern'
require 'psd/layer/info/placed_layer'
require 'psd/layer/info/reference_point'
require 'psd/layer/info/sheet_color'
require 'psd/layer/info/solid_color'
require 'psd/layer/info/typetool'
require 'psd/layer/info/unicode_name'
require 'psd/layer/info/vector_mask'
require 'psd/layer/info/vector_origination'
require 'psd/layer/info/vector_stroke'
require 'psd/layer/info/vector_stroke_content'

class PSD
  class Layer
    module Info
      # All of the extra layer info sections that we know how to parse.
      LAYER_INFO = {
        blend_clipping_elements: BlendClippingElements,
        blend_interior_elements: BlendInteriorElements,
        type: TypeTool,
        legacy_type: LegacyTypeTool,
        metadata: MetadataSetting,
        layer_name_source: LayerNameSource,
        object_effects: ObjectEffects,
        name: UnicodeName,
        section_divider: LayerSectionDivider,
        sheet_color: SheetColor,
        nested_section_divider: NestedLayerDivider,
        reference_point: ReferencePoint,
        layer_id: LayerID,
        fill_opacity: FillOpacity,
        placed_layer: PlacedLayer,
        locked: Locked,
        solid_color: SolidColor,
        vector_mask: VectorMask,
        vector_origination: VectorOrigination,
        vector_stroke: VectorStroke,
        vector_stroke_content: VectorStrokeContent,
        gradient_fill: GradientFill
      }.freeze

      attr_reader :adjustments
      alias :info :adjustments

      LAYER_INFO.keys.each do |key|
        define_method(key) { @adjustments[key] }
      end

      private

      # This section is a bit tricky to parse because it represents all of the
      # extra data that describes this layer.
      def parse_layer_info
        @extra_data_begin = @file.tell

        while @file.tell < @layer_end
          # Signature, don't need
          @file.seek 4, IO::SEEK_CUR

          # Key, very important
          key = @file.read_string(4)
          @info_keys << key

          length = Util.pad2 @file.read_int
          pos = @file.tell

          key_parseable = false
          LAYER_INFO.each do |name, info|
            next unless info.should_parse?(key)

            PSD.logger.debug "Layer Info: key = #{key}, start = #{pos}, length = #{length}"

            i = info.new(self, length)
            @adjustments[name] = LazyExecute.new(i, @file).now(:skip).later(:parse)

            key_parseable = true and break
          end

          unless key_parseable
            PSD.logger.debug "Skipping unknown layer info block: key = #{key}, length = #{length}"
            @file.seek length, IO::SEEK_CUR
          end
        end

        @extra_data_end = @file.tell
      end
    end
  end
end
