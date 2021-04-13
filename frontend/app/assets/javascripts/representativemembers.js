$(function () {
  function handleRepresentativeChange($subform, isRepresentative) {
    if (isRepresentative) {
      $subform.addClass('is-representative');
    } else {
      $subform.removeClass('is-representative');
    }

    $(':input[name$="[is_representative]"]', $subform).val(
      isRepresentative ? 1 : 0
    );

    $subform.trigger('formchanged.aspace');
  }

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      // TODO: generalize?
      if (
        object_name === 'file_version' ||
        object_name === 'instance' ||
        object_name == 'agent_contact'
      ) {
        var $subform = $(subform);
        var $section = $subform.closest('section.subrecord-form');
        var isRepresentative =
          $(':input[name$="[is_representative]"]', $subform).val() === '1';
        var local_publish_button = $subform.find('.js-file-version-publish');
        var local_make_rep_button = $subform.find('.is-representative-toggle');

        var eventName =
          'newrepresentative' + object_name.replace(/_/, '') + '.aspace';

        if (local_publish_button.prop('checked') == false) {
          local_make_rep_button.prop('disabled', true);
        } else {
          local_make_rep_button.prop('disabled', false);
        }

        $subform.find('.js-file-version-publish').click(function (e) {
          if (
            $subform.hasClass('is-representative') &&
            $(this).prop('checked', true)
          ) {
            handleRepresentativeChange($subform, false);
            $(this).prop('checked', false);
          }

          if ($(this).prop('checked') == false) {
            local_make_rep_button.prop('disabled', true);
          } else {
            local_make_rep_button.prop('disabled', false);
          }
        });

        $subform.find('.is-representative-toggle').click(function (e) {
          local_publish_button.prop('checked', true);
        });

        if (isRepresentative) {
          $subform.addClass('is-representative');
        }

        $('.is-representative-toggle', $subform).click(function (e) {
          e.preventDefault();

          $section.triggerHandler(eventName, [$(e.currentTarget).is('.cancel-representative') ? false : $subform])
        });

        $section.on(eventName, function (e, representative_subform) {
          handleRepresentativeChange(
            $subform,
            representative_subform == $subform
          );
        });
      }
  });


  function toggleThumbnail($subform, toggleOnOrOff) {
    if (toggleOnOrOff === 'off') {
      $subform.removeClass('is-thumbnail');
      $subform.find(':hidden[name$="[is_display_thumbnail]"]').val(0);
    } else {
      $subform.addClass('is-thumbnail');
      $subform.find(':hidden[name$="[is_display_thumbnail]"]').val(1);
    }
  }

  $(document).bind("subrecordcreated.aspace", function (event, object_name, subform) {
    if (object_name === "file_version") {
      const  $subform = $(subform);
      const  $section = $subform.closest("section.subrecord-form");

      if ($subform.find(':hidden[name$="[is_display_thumbnail]"]').val() === '1') {
        $subform.addClass('is-thumbnail');
      }

      $subform.on('click', '.is-thumbnail-toggle', function (e) {
        e.preventDefault();
        e.stopImmediatePropagation();

        toggleThumbnail($section.find('.is-thumbnail'), 'off');
        toggleThumbnail($subform, 'on');
      });

      $subform.on('click', '.cancel-thumbnail', function (e) {
        e.preventDefault();
        e.stopImmediatePropagation();

        toggleThumbnail($subform, 'off');
      });
    }
  });
});
