(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
            $('#matches').on('shown.bs.collapse', function (e) {
                methods.loadActivity(e.target);
            });
            methods.poll($('#processId').val());
		},
        
        loadMatches: function() {
            $.ajax({
				url:rootUrl + 'match/games/' + $("#systemCode").val() + '/' + $("#id").val() + '/' + $("#id2").val(),
				type:'GET',
				success:function(data){
					methods.poll(data);
				},
				error:function(jqXHR){
				    $('#matchCount').html(errorDiv('UNAVAILABLE'));
				}
			});
        },
        
        poll: function(processId) {
            $.ajax({
				url:rootUrl + 'process/poll/' + processId,
				type:'GET',
				success:function(data){
                    if (data.result) {
                        methods.show(data.result);
                    } else if (data.error) {
                        // Display the error
                        $('.progress').hide();
                        $('#matchCount').html(errorDiv(data.error));
                    } else {
                        // Update progress bar
                        var percent = Math.max(5, (data.progress / data.total) * 100);
                        var dots = $('.progress-value').html().split('.').length - 1;
                        $('.progress-bar').attr('aria-valuenow', Math.round(percent));
                        $('.progress-bar').css('width', percent + '%');
                        $('.progress-value').html('Loading' + ('.'.repeat((dots + 1) % 4)));
                        // Schedule another poll in 2 seconds
                        setTimeout(function() { methods.poll(data.id) }, 2000);
                    }
				},
				error:function(jqXHR){
				    $('#matchCount').html('UNAVAILABLE');
				}
			});
        },
        
        show: function(matches) {
            var matchOutput = '';
            for (i in matches) {
                var title = matches[i].activityType ? matches[i].activityType + ' - ' + matches[i].activityName : matches[i].activityName;
                matchOutput += '<div class="panel panel-default match">';
                matchOutput += '<a class="match-link" href="' + rootUrl + 'match/single/' + matches[i].id + '" target="_blank"><span class="glyphicon glyphicon-new-window" aria-hidden="true"></span></a>';
                matchOutput += '<div class="panel-heading" data-toggle="collapse" data-target="#cd-' + matches[i].id + '"><div class="tableDiv">'
                matchOutput += '<div class="activityCell"><img class="activityIcon" src="' + matches[i].activityIcon + '" title="' + title + '" /></div>';
                matchOutput += '<div class="dateCell">' + convertDateString(matches[i].period) + '</div>';
                matchOutput += '<div class="fillCell">';
                if (matches[i].sameTeam) {
                    matchOutput += ' <span class="glyphicon glyphicon-thumbs-up text-success" aria-hidden="true" title="Same Team"></span> ';
                }
                matchOutput += '</div>';
                matchOutput += '<div class="fillCell">';
                if (matches[i].result == 1) {
                    matchOutput += ' <span class="glyphicon glyphicon-ok text-success" aria-hidden="true" title="Win"></span> ';
                }
                matchOutput += '</div>';
                matchOutput += '<div class="fillCell">';
                if (Number(matches[i].kd) >= 1) {
                    matchOutput += ' <span class="text-success" aria-hidden="true">' + matches[i].kd + '</span> ';
                } else {
                    matchOutput += ' <span class="text-danger" aria-hidden="true">' + matches[i].kd + '</span> ';
                }
                matchOutput += '</div>';
                matchOutput += '</div></div>';
                matchOutput += '<div class="panel-collapse collapse" id="cd-' + matches[i].id + '"><div class="panel-body">';
                matchOutput += '<input type="hidden" value="' + matches[i].id + '" />';
                matchOutput += '<span class="loading-spinner" style="display: none;"></span>';
                matchOutput += '</div></div>';
                matchOutput += '</div>';
            }
            $('.progress').hide();
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
            //var t = 0;
            for (var t in teamStats) {
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
            var hasScores = playerStats[0].score != "0"
            output = '<table class="table table-striped players">';
            output += '<thead>';
            output += '<tr>';
            output += '<th></th>';
            output += '<th>K</th>';
            output += '<th>A</th>';
            output += '<th>D</th>';
            output += '<th>K/D</th>';
            if (hasScores) {
                output += '<th>S</th>';
            }
            output += '</tr>';
            output += '</thead>';
            output += '<tbody>';
            //var p = 0;
            for (var p in playerStats) {
                playerStat = playerStats[p];
                output += '<tr class="player">';
                output += '<td rowspan="3" class="iconCell"><img class="activityIcon" src="' + playerStat.playerIcon + '" title="' + playerStat.name + '" /></td>';
                output += '<td>' + playerStat.k + '</td>';
                output += '<td>' + playerStat.a + '</td>';
                output += '<td>' + playerStat.d + '</td>';
                output += '<td>' + playerStat.kd + '</td>';
                if (hasScores) {
                    output += '<td>' + playerStat.score + '</td>';
                }
                output += '</tr>';
                output += '<tr class="invisRow"></tr>';
                output += '<tr class="player">';
                output += '<td colspan="3">' + playerStat.name + '</td>';
                output += '<td colspan="2" style="font-size: smaller; text-align: right">' + playerStat.class + ' ' + playerStat.level + '</td>';
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
