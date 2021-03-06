window.pong = window.pong || {};

pong.PlayerSearchView = Backbone.View.extend({
  template: JST['templates/playerSearch'],
  selectedIndex: -1,
  active: false,

  initialize: function (options) {
    this.collection = new pong.PlayerSearch();
    this.collection.on('sync', this.render, this);
    this.collection.on('reset', this.render, this);
    this.onMousedownCallback = options.onMousedownCallback;
  },

  render: function () {
    this.$el.off('click');

    this.$el.html(this.template({
      names: this.collection.playerNames(),
    }));

    if (this.active)
      this.options().eq(this.selectedIndex).addClass('selected');
    this.$el.on('mousedown', _.bind(this.mousedownHandler, this));
    this.$el.on('mouseover', _.bind(this.mouseOverHandler, this));
  },

  mousedownHandler: function (e) {
    if (e.target.localName === 'li') {
      this.onMousedownCallback(e.target.textContent);
      this.collection.reset();
    }
  },

  mouseOverHandler: function(e) {
      if(e.target.localName === 'li') {
          this.deactivateKeyboardNavigation();
          this.deselect();
          $(e.target).addClass('selected');
      }
  },

  deselect: function() {
      this.$el.find('.selected').removeClass('selected');
  },

  deactivateKeyboardNavigation: function() {
      this.active = false;
      this.selectedIndex = -1;
      this.deselect();
      this.$el.removeClass('active');
  },

  activateKeyboardNavigation: function() {
    this.active = true;
    this.$el.addClass('active');
  },

  selectNext: function() {
      this.activateKeyboardNavigation();
      this.selectedIndex += 1;
      this.constrainIndex();
  },

  selectPrev: function() {
      this.activateKeyboardNavigation();
      this.selectedIndex -= 1;
      this.constrainIndex();
  },

  enterSelected: function() {
      var li = this.options().eq(this.selectedIndex);
      this.onMousedownCallback(li.text());
      this.collection.reset();
      this.deactivateKeyboardNavigation();
  },

  constrainIndex: function() {
      this.selectedIndex = Math.max(0, Math.min(this.selectedIndex, this.options().length - 1));
  },

  options: function() {
      return this.$el.find('li');
  },
});
