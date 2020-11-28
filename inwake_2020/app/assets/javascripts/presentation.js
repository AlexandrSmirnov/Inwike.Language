animation = null;

function animateCalendar() {
	var lessons = [
		{left: '44%', top: '71%'},
		{left: '44%', top: '80.5%'},
		{left: '55%', top: '80.5%'},
		{left: '65.5%', top: '71%'},
		{left: '65.5%', top: '80.5%'}
	];
	var lastLesson = 0;

	if (animation) {
		clearTimeout(animation);
	}
	$('.calendar').find('.calendar__label').remove();

	animateLesson = function() {
		if (lessons.length === lastLesson) {
			return;
		}

		$('.calendar__btn')
			.clone()
			.data('position', lessons[lastLesson])
			.insertAfter('.calendar__btn')
			.animate(lessons[lastLesson], 1300, function(){
				$('.calendar').append('<div class="calendar__label"></div>');
				$('.calendar').find('.calendar__label:last-child').css($(this).data('position'));
				$(this).remove();
			})

		lastLesson++;
		animation = setTimeout(animateLesson, 4000);
	}
	animateLesson();
}

function animateDiary() {
	if (animation) {
		clearTimeout(animation);
	}

	$('.diary__label').hide();

	animateTask = function(selector, timeout, callback) {
		animation = setTimeout(function() {
			$(selector).fadeIn(callback);
		}, timeout);
	};

	animateTask('.diary__label_1', 1500, animateTask('.diary__label_2', 4000));
}

function animateDiaryTree() {
	if (animation) {
		clearTimeout(animation);
	}

	$('.diary-tree__label').remove();

	var labels = ['diary-tree__label_1', 'diary-tree__label_2', 'diary-tree__label_3'];
	var lastLabel = 0;

	animateDiaryLabel = function() {
		if (labels.length === lastLabel) {
			return;
		}

		$('.diary-tree').append('<div class="diary-tree__label ' + labels[lastLabel] + '"></div>');
		$('.diary-tree .' + labels[lastLabel]).fadeIn();

		lastLabel++;
		animation = setTimeout(animateDiaryLabel, 3000);
	}
	animation = setTimeout(animateDiaryLabel, 2000);
}

document.addEventListener('impress:stepenter', function(event) {
  	if ( event.target.id === 'step-5' ) {
  		animateCalendar();
  	}
  	if ( event.target.id === 'step-7' ) {
  		animateDiary();
  	}
  	if ( event.target.id === 'step-8' ) {
  		animateDiaryTree();
  	}
}, false);