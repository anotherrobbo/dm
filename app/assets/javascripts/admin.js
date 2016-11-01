(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
            $('.dateCell').each(function() {
                var dateString = $(this).html();
                $(this).html(convertDateString(dateString));
            });

            var procType = $('#processType').val();
            if (procType == 'BULK') {
            	methods.pollBulk($('#processId').val());
            }
		},

		pollBulk: function(processId) {
            $.ajax({
				url:rootUrl + 'process/poll/' + processId,
				type:'GET',
				success:function(data){
                    if (!data.running) {
                        $('#progress').append('DONE');
                    } else if (data.error) {
                        // Display the error
                        $('#progress').append(errorDiv(data.error));
                    } else if ($('#' + data.current, $('#progress')).length) {
                        // Update dots
                        var dots = $('#' + data.current, $('#progress')).html().split('.').length - 1;
                        $('#' + data.current, $('#progress')).html(data.current + ('.'.repeat((dots + 1) % 4)));
                        // Schedule another poll in 2 seconds
                        setTimeout(function() { methods.pollBulk(data.id) }, 2000);
                    } else {
                        var newDiv = '<div id="' + data.current + '">' + data.current + '</div>';
                        $('#progress').append(newDiv);
                        // Schedule another poll in 2 seconds
                        setTimeout(function() { methods.pollBulk(data.id) }, 2000);
                    }
				},
				error:function(jqXHR){
				    $('#matchCount').html('UNAVAILABLE');
				}
			});
		}
	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);