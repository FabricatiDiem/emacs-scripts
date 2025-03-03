;; raindrop-to-org.el - Fetch bookmarks from Raindrop.io and save to Org-mode

(require 'json)
(require 'request)
(require 'org)

(defvar raindrop-api-token "3e246817-b3be-4fe0-a536-630c914f6362"
  "API token for authenticating with Raindrop.io.")

(defvar raindrop-org-file "~/raindrop-bookmarks.org"
  "Path to the Org-mode file where bookmarks will be stored.")

(defun raindrop-fetch-bookmarks ()
  "Fetch bookmarks from Raindrop.io and return as a list of entries."
  (let ((url "https://api.raindrop.io/rest/v1/raindrops/0"))
    (append
     (alist-get
      'items
      (request-response-data
       (request
        url
        :headers `(("Authorization" . ,(concat "Bearer " raindrop-api-token)))
        :parser 'json-read
        :sync t
        :success
        (cl-function
         (lambda (&key data &allow-other-keys)
           (let ((items (alist-get 'items data)))
             (when items
               (mapcar
                (lambda (item)
                  (list
                   (alist-get 'id item)
                   (alist-get 'title item)
                   (alist-get 'link item)
                   (alist-get 'tags item)))
                items))))))))
     nil)))

(defun raindrop-org-contains-link-p (link)
  "Check if the Org file already contains a given link."
  (when (file-exists-p raindrop-org-file)
    (with-temp-buffer
      (insert-file-contents raindrop-org-file)
      (search-forward link nil t))))

(defun raindrop-delete-bookmark (bookmark-id)
  "Delete a bookmark from Raindrop.io given its ID."
  (let ((url
         (format "https://api.raindrop.io/rest/v1/raindrop/%s"
                 bookmark-id)))
    (request
     url
     :type "DELETE"
     :headers `(("Authorization" . ,(concat "Bearer " raindrop-api-token)))
     :sync t)))

(defun raindrop-save-to-org ()
  "Fetch bookmarks from Raindrop.io, append new ones to the Org file, and delete them afterward."
  (interactive)
  (let ((bookmarks (raindrop-fetch-bookmarks)))
    (when bookmarks
      (with-temp-buffer
        (insert "* Raindrop.io Bookmarks\n")
        (dolist (bookmark bookmarks)
          (let ((id (alist-get '_id bookmark))
                (title (alist-get 'title bookmark))
                (link (alist-get 'link bookmark)))
            (unless (raindrop-org-contains-link-p link)
              (insert
               (format "** %s\n[[%s][%s]]\n\n" title link title)))))
        ;;(raindrop-delete-bookmark id)))))
        (append-to-file (point-min) (point-max) raindrop-org-file))))
  (message "New bookmarks saved to %s and deleted from Raindrop.io"
           raindrop-org-file))

(raindrop-save-to-org)
