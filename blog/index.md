---
layout: page
title: Blog
excerpt: "An archive of blog posts sorted by date."
search_omit: true
---
<ul class="post-list">
{% for post in site.posts %} 
  <li>
    <article>
      <a href="{{ site.url }}{{ post.url }}">{{ post.title }}
        <span class="entry-date"><time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %d, %Y" }}</time></span>
        {% if post.excerpt %} <span class="excerpt">{{ post.excerpt | remove: '\[ ... \]' | remove: '\( ... \)' | markdownify | strip_html | strip_newlines | escape_once }}</span>
	<img src="{{ site.url }}/images/{{ post.image.teaser }}" alt="teaser">
      	{% endif %}
	</a>
    </article>
  </li>
{% endfor %}
</ul>

{% include google_analytics.html %}