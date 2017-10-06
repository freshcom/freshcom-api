function map(array, callback_func) {
  let result = []

  for (var i = array.length - 1; i >= 0; i--) {
    let item = array[i]
  }


  return result
}


var reversing = function () {
  return word.split('').reverse().join('');
}

map(words, reversing);

///////////////


map(words, function(word) {
  return word.split('').reverse().join('');
});