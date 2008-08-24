require 'rubygems'
require 'pathname'

gem 'dm-core', '>=0.9.4'
require 'dm-core'

dir = Pathname(__FILE__).dirname.expand_path / 'sphinx-for-dm'

require dir / 'sphinx_client'

if defined?(Merb::Plugins)
  Merb::Plugins.add_rakefiles(dir / 'merbtasks')
end

module DataMapper
  module Sphinx

    VERSION = '0.9.4'

    def self.included(base)
      base.extend(ClassMethods)
      base.class_inheritable_accessor :sphinx_options
      default_options = {:host => 'localhost', :port => 3312, :index => Extlib::Inflection.tableize(base.name)}
      base.sphinx_options = default_options
    end

    module ClassMethods
    
  #    VALID_OPTIONS = %w[mode offset page limit index weights host 
  #                       port range filter filter_range group_by sort_mode].map(&:to_sym)

      def sphinx_index
        @@sphinx_options[:index]
      end
      
      def sphinx_options
        @@sphinx_options
      end
      
      def ask_sphinx(query, options = {})
        default_options = {:offset => 0, :limit => 1000}
        default_options.merge! sphinx_options
        options = default_options.merge! options
        
        if options[:page] && options[:limit]
          options[:offset] = options[:limit] * (options[:page].to_i - 1)
          options[:offset] = 0 if options[:offset] < 0
        end
        
        sphinx = SphinxClient.new
        sphinx.set_server options[:host], options[:port]
        sphinx.set_limits options[:offset], options[:limit]
        sphinx.set_weights options[:weights] if options[:weights]
        sphinx.set_id_range options[:range] if options[:range]
        
        options[:filter].each do |attr, values|
          sphinx.set_filter attr, [*values]
        end if options[:filter]
        
        options[:filter_range].each do |attr, (min, max)|
          sphinx.set_filter_range attr, min, max
        end if options[:filter_range]
        
        options[:group_by].each do |attr, func|
          funcion = SphinxClient.const_get("SPH_GROUPBY_#{func.to_s.upcase}") \
            rescue raise("Unknown group by function #{func}")
          sphinx.set_group_by attr, funcion
        end if options[:group_by]
        
        if options[:mode]
          match_mode = SphinxClient.const_get("SPH_MATCH_#{options[:mode].to_s.upcase}") \
            rescue raise("Unknown search mode #{options[:mode]}")
          sphinx.set_match_mode match_mode
        end
        
        if options[:sort_mode]
          sort_mode, sort_expr = options[:sort_mode]
          sort_mode = SphinxClient.const_get("SPH_SORT_#{sort_mode.to_s.upcase}") \
            rescue raise("Unknown sort mode #{sort_mode}")
          sphinx.set_sort_mode sort_mode, sort_expr
        end
        
        sphinx.query query, options[:index]
      end
      
      def all_with_sphinx(query, options = {})
        result = ask_sphinx(query, options)
        records = result[:matches].empty? ? [] : all(({ :id.in => result[:matches].keys }).merge(options).merge({:limit => 1000, :offset => 0}))
        records = records.sort_by{|r| - result[:matches][r.id][:weight] }
        %w[total total_found time].map(&:to_sym).each do |method|
          class << records; self end.send(:define_method, method) {result[method]}
        end
        records
      end
    
    end # SphinxClassMethods

  end # Sphinx

  Resource::append_inclusions Sphinx

end # DataMapper
