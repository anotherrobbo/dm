function convertDateString(dateString) {
    var epochMillis = Date.parse(dateString);
    var localeDate = new Date(epochMillis);
    return formatDate(localeDate);
}

function formatDate(date) {
    return date.getFullYear() + "/" + padNum(date.getMonth()) + "/" + padNum(date.getDate()) + " " + padNum(date.getHours()) + ":" + padNum(date.getMinutes());
}

function padNum(num) {
    return num < 10 ? "0" + num : num;
}

(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
		    /*$('#submit').click(function() {
		        methods.go();
		    });
            */
            methods.loadMatches();
		},
        
        loadMatches: function() {
            $.ajax({
				url:rootUrl + 'match/games/' + $("#systemCode").val() + '/' + $("#id").val() + '/' + $("#id2").val(),
				type:'GET',
                //data:{'un':$('#un').val()},
				success:function(data){
					methods.show(data);
				},
				error:function(jqXHR){
				    $('#matchCount').html('UNAVAILABLE');
				}
			});
        },
        
        show: function(matches) {
            var matchOutput = '';
            for (i in matches) {
                matchOutput += '<div class="panel panel-default match">';
                matchOutput += '<div class="panel-heading" data-toggle="collapse" data-target="#cd-' + matches[i].id + '"><img class="activityIcon" src="' + matches[i].activityIcon + '" title="' + matches[i].activityName + '" /> ';
                matchOutput += convertDateString(matches[i].time);
                matchOutput += '</div>';
                matchOutput += '<div class="panel-collapse collapse" id="cd-' + matches[i].id + '"><div class="panel-body">';
                matchOutput += matches[i].id + ' ';
                matchOutput += matches[i].result + ' ';
                matchOutput += '</div></div>';
                matchOutput += '</div>';
            }
            $('.loading-spinner').hide();
            $('#matches').html(matchOutput);
            $('#matchCount').html(matches.length + ' matches found');
		}

	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);