// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

$(function() {
    $('.quarantine_link').click(function() {
	while(true) {
	    var note = window.prompt(this.dataset.note, "");
	    if(note == null) { return false; }
	    if(!note) { alert(this.dataset.error); continue;}
	    this.href = this.href+"&note="+encodeURIComponent(note);
	    return true;
	}
    });
});

$(function () {
//    $('#job_list th a, #job_list .pagination a').live('click', function () {
//	$.getScript(this.href);
//	return false;
//    });
    
    
    $('#job_list_search input').keyup(function () {
        $('#f_o').val('');
        $('#f_c').val('');
        $('#f_s').val('');
        $('#f_p').val('');
        $.get($('#job_list_search').attr('action'), 
          $('#job_list_search').serialize(), null, 'script');
    return false;
    });
});

// Filter by Owner
$(function() {
    $('#f_o').on('change', function() {
        $('#f_c').val('');
        $('#f_s').val('');
        $('#f_p').val('');
        var option = $('#f_o option[value="'+this.value+'"]').text();
        $('#job_list_search').submit();
        return true;
    });
});

// Filter by Creted by
$(function() {
    $('#f_c').on('change', function() {
        $('#f_o').val('');
        $('#f_s').val('');
        $('#f_p').val('');
        var option = $('#f_c option[value="'+this.value+'"]').text();
        $('#job_list_search').submit();
        return true;
    });
});

// Filter by Status
$(function() {
    $('#f_s').on('change', function() {
        $('#f_o').val('');
        $('#f_c').val('');
        $('#f_p').val('');
        var option = $('#f_s option[value="'+this.value+'"]').text();
        $('#job_list_search').submit();
        return true;
    });
});

// Filter by Project
$(function() {
    $('#f_p').on('change', function() {
        $('#f_o').val('');
        $('#f_c').val('');
        $('#f_s').val('');
        var option = $('#f_p option[value="'+this.value+'"]').text();
        $('#job_list_search').submit();
        return true;
    });
});

$(function() {
    $('.editable_form').on('dblclick', function() {
	$(this).find('.form').show();
	$(this).find('.plain').hide();
    });

});


$(function() {
    $('.editable_form_name').on('dblclick', function() {
	$(this).find('.form').show();
	$(this).find('.plain').hide();
    });

});

$(function() {
    $('#job_new_status').on('change', function() {
	var option = $('#job_new_status option[value="'+this.value+'"]').text();
	var choice = window.confirm("Bekräfta statusbyte till\n"+option);
	if(choice == false) {
	    var old_value = $('#job_new_status option[selected="selected"]').val();
	    $('#job_new_status').val(old_value);
	    return false;
	} else {
	    $('#job_select').submit();
	    return true;
	}
    });
});

$(function() {
    $('#job_new_project').on('change', function() {
	var option = $('#job_new_project option[value="'+this.value+'"]').text();
	var choice = window.confirm("Bekräfta projektbyte till\n"+option);
	if(choice == false) {
	    var old_value = $('#job_new_project option[selected="selected"]').val();
	    $('#job_new_project').val(old_value);
	    return false;
	} else {
	    $('#job_move_select').submit();
	    return true;
	}
    });
});

$(function() {
    $('#job_new_copyright').on('change', function() {
    var option = $('#job_new_copyright option[value="'+this.value+'"]').text();
    var choice = window.confirm("Bekräfta copyrightbyte till\n"+option);
    if(choice == false) {
        var old_value = $('#job_new_copyright option[selected="selected"]').val();
        $('#job_new_copyright').val(old_value);
        return false;
    } else {
        $('#job_copyright_select').submit();
        return true;
    }
    });
});

$(function(){
  $('.toggleLink_xml').click(function(){
           $('#xml').slideToggle({duration: 300});
       });
});

$(function(){
  $('.toggleLink_activity_log').click(function(){
           $('#activity_log').slideToggle({duration: 300});
       });
});

$(function(){
  $('.toggleLink_prioritized_jobs').click(function(){
           $('#prioritized_jobs').slideToggle({duration: 300});
       });
});



