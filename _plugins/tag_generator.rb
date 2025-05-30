module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      site.tags.each do |tag, posts|
        tag_slug = Jekyll::Utils.slugify(tag)
        site.pages << TagPage.new(site, site.source, tag, tag_slug, posts)
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, tag, tag_slug, posts)
      @site = site
      @base = base
      @dir  = File.join('blog', 'tag', tag_slug)
      @name = 'index.html'
      @path = File.join(@base, @dir, @name)

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tagpage.html')
      self.data['layout'] = 'tagpage'  # Explicitly set the layout
      self.data['tag'] = tag           # original tag name for display and filtering
      self.data['tag_slug'] = tag_slug # slug for URL
      self.data['title'] = tag         # for display
      self.data['posts'] = posts       # list of posts for this tag
      self.data['description'] = "#{posts.size} post#{posts.size == 1 ? '' : 's'} tagged with '#{tag}'"
    end
  end
end 