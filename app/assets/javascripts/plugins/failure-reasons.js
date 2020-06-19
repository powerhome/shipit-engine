const API_URL = '/api/failure_reasons/',
  DEFAULT_MESSAGE = 'Deployment failed. Please classify failure reason:',
  EMPTY_FAILURE_REASON = 'Failure reason can not be blank',
  ERROR_MESSAGE = 'Failure Reason Could Not Be Updated',
  FAILURE_BANNER = '<div id="failure-banner" class="failure-banner"></div>',
  OTHER_VALUE = 'other';

let taskId;

function getFailureReasons(task_id) {
  fetch(API_URL + '?task_id=' + task_id)
    .then(response => response.text())
    .then(html => renderFailureReasons(html));
}

function getToken() {
  return document.getElementsByName('csrf-token')[0].content;
}

function postFailureReasons(failureReason, failureReasonOther) {
  let payload = {
      'task_id': taskId,
      'failure_reason_id': failureReason,
      'failure_reason_other': failureReasonOther
    },
    isUpdate = (failureReason != OTHER_VALUE),
    url = (isUpdate) ? API_URL + taskId + '/' : API_URL + '';

  fetch(url, {
      method: (isUpdate) ? 'PUT' : 'POST',
      body: JSON.stringify(payload),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': getToken()
      }
    })
    .then(response => {
      if (!response.ok) {
        response.text()
          .then(message => {
            throw new Error(message)
          })
          .catch(error => {
            console.error(ERROR_MESSAGE, error)
            alert(ERROR_MESSAGE + '\n' + error);
          });
      } else {
        response.text().then(html => renderFailureReasons(html))
      }
    })
}

function renderFailureReasons(html) {
  document.getElementById('failure-banner').innerHTML = html;
}

function toggleFailureReason(select) {
  let otherInput = document.getElementById('failure-reason-other'),
    save = document.getElementById('save-failure-reason');

  otherInput.style.display = select.value == OTHER_VALUE ? '' : 'none';
  save.style.display = '';
}

function validateFailureReason() {
  let failureReason = document.getElementById('failure-reason'),
    failureReasonOther = document.getElementById('failure-reason-other');

  if (failureReason.value == OTHER_VALUE && failureReasonOther.value.length == 0) {
    alert(EMPTY_FAILURE_REASON);
    return;
  }

  postFailureReasons(failureReason.value, failureReasonOther.value);
}

document.addEventListener("DOMContentLoaded", function () {
  let deployBanner = document.querySelector('.deploy-banner'),
    deployStatus = deployBanner.getAttribute('data-status'),
    deployFailure = deployStatus == 'failed',
    task_id = window.location.href.split('/deploys/')[1];

  if (!deployFailure) return;

  // Create initial root element
  deployBanner.insertAdjacentHTML('afterEnd', FAILURE_BANNER);

  taskId = task_id;
  getFailureReasons(task_id);
});
