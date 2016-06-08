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
				url:'/match/games/' + $("#systemCode").val() + '/' + $("#id").val() + '/' + $("#id2").val(),
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
                matchOutput += '<div class="match">';
                matchOutput += '<div class="date">' + convertDateString(matches[i].time) + '</div>';
                matchOutput += '<img class="activityIcon" src="' + matches[i].activityIcon + '" title="' + matches[i].activityName + '" />';
                matchOutput += matches[i].id + ' ';
                matchOutput += matches[i].result + ' ';
                matchOutput += '</div>';
                //<input class="hdate" type="hidden" value="<%= @match.time.to_json %>"><div class="date"></div><%= @match.id %> <%= @match.activityType %> <%= @match.result %></div>
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