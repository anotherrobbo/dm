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
            $('#matches').on('shown.bs.collapse', function (e) {
                methods.loadActivity(e.target);
            });
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
                if (matches[i].sameTeam) {
                    matchOutput += ' <span class="glyphicon glyphicon-thumbs-up" aria-hidden="true"></span> ';
                } else {
                    matchOutput += ' <span class="glyphicon glyphicon-thumbs-down" aria-hidden="true"></span> ';
                }
                if (matches[i].result == 'V') {
                    matchOutput += ' <span class="glyphicon glyphicon-ok" aria-hidden="true"></span> ';
                } else {
                    matchOutput += ' <span class="glyphicon glyphicon-remove" aria-hidden="true"></span> ';
                }
                matchOutput += matches[i].kd;
                matchOutput += '</div>';
                matchOutput += '<div class="panel-collapse collapse" id="cd-' + matches[i].id + '"><div class="panel-body">';
                matchOutput += '<input type="hidden" value="' + matches[i].id + '" />';
                matchOutput += '<span class="loading-spinner" style="display: none;"></span>';
                matchOutput += '</div></div>';
                matchOutput += '</div>';
            }
            $('.loading-spinner').hide();
            $('#matches').html(matchOutput);
            $('#matchCount').html(matches.length + ' matches found');
		},
        
        loadActivity: function(collapsable) {
            // Check if we've already loaded the data
            if (!$('.panel-body .activityData', collapsable).length) {
                $('.panel-body .loading-spinner', collapsable).show();
                $.ajax({
                    url:rootUrl + 'match/details/' + $('.panel-body input[type="hidden"]', collapsable).val(),
                    type:'GET',
                    success:function(data, status, jqXHR){
                        $('.panel-body', collapsable).append('<div class="activityData">' + methods.showActivity(data) + '</div>');
                    },
                    error:function(jqXHR, status, error){
                        $('.panel-body', collapsable).append('<div class="activityData">ERROR</div>');
                    },
                    complete:function(jqXHR, status){
                        $('.panel-body .loading-spinner', collapsable).hide();
                    }
                });
            }
        },
        
        showActivity: function(data) {
            if (data.teamStats && data.teamStats.length) {
                return methods.showTeams(data.teamStats);
            } else {
                return methods.showPlayers(data.playerStats);
            }
        },
        
        showTeams: function(teamStats) {
            output = '';
            for (t in teamStats) {
                teamStat = teamStats[t];
                output += '<div class="team team-' + teamStat.name + '">';
                output += '<div class="panel-heading">';
                output += teamStat.name + ' ' + teamStat.score + ' ' + teamStat.result;
                output += '</div>';
                output += methods.showPlayers(teamStat.playerStats);
                output += '</div>';
            }
            return output;
        },
        
        showPlayers: function(playerStats) {
            //output = '<div class="players">';
            output = '<table class="table table-striped table-hover players">';
            output += '<thead>';
            output += '<tr>';
            output += '<th>P</th>';
            output += '<th>K</th>';
            output += '<th>A</th>';
            output += '<th>D</th>';
            output += '<th>K/D</th>';
            output += '<th>S</th>';
            output += '</tr>';
            output += '</thead>';
            output += '<tbody>';
            for (p in playerStats) {
                playerStat = playerStats[p];
                output += '<tr class="player">';
                output += '<td><img class="activityIcon" src="' + playerStat.playerIcon + '" title="' + playerStat.name + '" /> ' + playerStat.name + '</td>';
                output += '<td>' + playerStat.k + '</td>';
                output += '<td>' + playerStat.a + '</td>';
                output += '<td>' + playerStat.d + '</td>';
                output += '<td>' + playerStat.kd + '</td>';
                output += '<td>' + (playerStat.score ? playerStat.score : '') + '</td>';
                output += '</tr>';
            }
            output += '</tbody></table>'
            return output;
        }

	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);