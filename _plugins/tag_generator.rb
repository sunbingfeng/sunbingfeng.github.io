module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      site.tags.each do |tag, posts|
        site.pages << TagPage.new(site, site.source, tag, posts)
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, tag, posts)
      @site = site
      @base = base
      @dir  = File.join('blog', 'tag', tag)
      @name = 'index.html'
      @path = File.join(@base, @dir, @name)

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['title'] = "Posts tagged with '#{tag}'"
      self.data['description'] = "#{posts.size} post#{posts.size == 1 ? '' : 's'} tagged with '#{tag}'"
    end
  end
end 