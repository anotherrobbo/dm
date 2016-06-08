(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
		    $('#submit').click(function() {
		        methods.go();
		    });
		},
        
        go: function() {
            var system = $('#system').val();
            var name = $('#name').val();
            var un2 = $('#un2').val();
			window.location = '/match/' + system + '/' + name + '/' + un2;
		}
	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);