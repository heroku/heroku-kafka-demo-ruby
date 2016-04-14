function main() {
  fetchMessages();
}

function fetchMessages() {
  $.ajax({
    dataType: 'json',
    url: "/messages",
    complete: function (data) {
      var table = $('.messages');
      table.empty();
      table.append('<tr><td>Offset</td><td>Partition</td><td>Message</td></tr>')
      for (var i = 0; i < data.responseJSON.length; i++) {
        var message = data.responseJSON[i]
        table.append('<tr><td>' + message.offset + '</td><td>' + message.partition + '</td><td>' + message.value + '</td></tr>')
      }
      setTimeout(function () {
        fetchMessages();
      }, 10000);
    }
  });
}

main()
