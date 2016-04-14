function main() {
  fetchMessages();
}

function fetchMessages() {
  $.ajax({
    dataType: 'json',
    url: "/messages",
    complete: function (data) {
      var ul = $('.messages');
      ul.empty();
      for (var i = 0; i < data.responseJSON.length; ++i) {
        ul.append("<li>" + data.responseJSON[i] + "</li>");
      }
      setTimeout(function () {
        fetchMessages();
      }, 10000);
    }
  });
}

main()
