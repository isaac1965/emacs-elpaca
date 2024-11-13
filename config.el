(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Instalar soporte para use-package
(elpaca elpaca-use-package
  (elpaca-use-package-mode))

;; Instalar y configurar Evil
(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-integration t)  ;; Integración con otros modos
  (setq evil-want-keybinding nil)  ;; Desactivar las vinculaciones de teclas predeterminadas
  (setq evil-vsplit-window-right t) ;; Ventanas verticales a la derecha
  (setq evil-split-window-below t)  ;; Ventanas horizontales abajo
  (evil-mode 1))  ;; Activar Evil Mode al inicio

;; Configuración adicional para Emacs
(use-package emacs
  :ensure nil
  :config
  (setq ring-bell-function #'ignore))  ;; Ignorar el sonido de campana

(elpaca general
  (general-evil-setup)

  ;; Configuración del leader key 'SPC'
  (general-create-definer dt/leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC" ;; definir leader
    :global-prefix "M-SPC") ;; acceso al leader en modo insert

  (dt/leader-keys
    "b" '(:ignore t :wk "buffer")
    "bb" '(switch-to-buffer :wk "Switch buffer")
    "bk" '(kill-this-buffer :wk "Kill this buffer")
    "bn" '(next-buffer :wk "Next buffer")
    "bp" '(previous-buffer :wk "Previous buffer")
    "br" '(revert-buffer :wk "Reload buffer"))

  ;; Configurar el atajo "jj" para salir del modo de inserción
  (general-imap "jj" 'evil-normal-state))

  (setq blink-cursor-mode nil) ;; Disable cursor blinking

(set-face-attribute 'default nil
  :font "JetBrains Mono Nerd Font"
  :height 110
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "Ubuntu Nerd Font"
  :height 120
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "JetBrains Mono Nerd Font"
  :height 110
  :weight 'medium)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
  :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-11"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.12)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(global-visual-line-mode t)

(elpaca which-key
 (which-key-mode 1)
 (setq which-key-side-window-location 'bottom
       which-key-sort-order #'which-key-key-order-alpha
       which-key-sort-uppercase-first nil
       which-key-add-column-padding 1
       which-key-max-display-columns nil
       which-key-min-display-lines 6
       which-key-side-window-slot -10
       which-key-side-window-max-height 0.25
       which-key-idle-delay 0.8
       which-key-max-description-length 25
       which-key-allow-imprecise-window-fit t
       which-key-separator " → "))

(elpaca dashboard
 (require 'dashboard)
 (dashboard-setup-startup-hook)

 ;; Configuración de opciones de dashboard
 (setq dashboard-banner-logo-title "Welcome to Emacs!"
       dashboard-startup-banner "~/Descargas/"    ;; También puedes usar un número (150) para una imagen o la ruta a un archivo
       dashboard-center-content t
       dashboard-items '((recents  . 5)       ;; Muestra los 5 archivos recientes
                         (bookmarks . 5)     ;; Muestra los 5 bookmarks
                         (projects . 5)      ;; Muestra los 5 proyectos más recientes
                         (agenda . 5)        ;; Muestra las 5 próximas entradas de agenda
                         (registers . 5))    ;; Muestra los 5 registros

       ;; Personaliza la sección de footer
       dashboard-set-footer nil
       dashboard-footer-messages '("Emacs is the editor of a lifetime!"))

 ;; Configurar inicialización
 (setq initial-buffer-choice (lambda () (get-buffer "*dashboard*"))))
