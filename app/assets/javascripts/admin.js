(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
            $('.dateCell').each(function() {
                var dateString = $(this).html();
                $(this).html(convertDateString(dateString));
            });
		}
	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);