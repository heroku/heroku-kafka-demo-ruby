function main() {
  fetchMessages();
}

function fetchMessages() {
  $.ajax({
    dataType: 'json',
    url: "/messages",
    success: function (data) {
      var ul = $('.messages');
      ul.empty();
      for (var i = 0; i < data.length; ++i) {
        ul.append("<li>" + data + "</li>");
      }
      setTimeout(function () {
        fetchMessages();
      }, 10000);
    }
  });
}

main()
