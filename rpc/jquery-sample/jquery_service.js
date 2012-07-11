new rpc.Service('jquery-widget/autocomplete', {
  autocomplete: function(id, options) {
    $(id).autocomplete(options);
  },
}).expose();
