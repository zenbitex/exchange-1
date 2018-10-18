// 英数字記号の全角文字を半角へ変換
  app.directive('convertMbToAscii', function () {
        return {
            restrict: 'A',
            require: '?ngModel',
            link: function (scope, element, attrs, ngModel) {
                element.on('change', function(){
                    if(typeof(this.value)!="string") return false;
                    var word = this.value;
                    word = word.replace(/[！＂＃＄％＆＇（）＊＋，－．／０-９：；＜＝＞？＠Ａ-Ｚ［＼］＾＿｀ａ-ｚ｛｜｝～]/g, function(s) {
                        return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
                    });
                    // ng-model への反映(これがないとフォームの値だけ更新され、ng-modelの値は更新されない)
                    if (ngModel != null) {
                        scope.$apply(function() {
                            ngModel.$setViewValue(word);
                        });
                    }
                    this.value = word;
                });
            }
        };
    })
