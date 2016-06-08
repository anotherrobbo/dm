(function($){  
	var methods = {
		// Initialise plugin.
		init: function() {
		    $('#search-form').submit(function(event) {
		        methods.search();
                event.preventDefault();
		    });
		},

		search: function() {
            $('#results').html('');
            $('.loading-spinner').show();
			$.ajax({
				url:'/search',
				type:'GET',
                data:{'un':$('#un').val()},
				success:function(data){
					$('.loading-spinner').hide();
                    if (data.length == 0) {
                        $('#results').html('NO RESULTS');
                    } else if (data.length == 1) {
                        methods.load(data[0]);
                    } else {
                        methods.show(data);
                    }
				},
				error:function(jqXHR){
				    $('.loading-spinner').hide();
                    $('#results').html('UNAVAILABLE');
				}
			});
		},
        
        load: function(p) {
			window.location = '/overview/' + p.system + '/' + p.name;
		},
        
        show: function(ps) {
			var results = '';
            for (i in ps) {
                results += '<div>';
                results += '<a href="/overview/' + ps[i].system + '/' + ps[i].name + '">' + ps[i].system + ' ' + ps[i].name + '</a>';
                results += '<div>';
            }
            $('#results').html(results);
		}
	};
	
	$(document).ready(function(){
		methods.init();
	});
	
})(jQuery);