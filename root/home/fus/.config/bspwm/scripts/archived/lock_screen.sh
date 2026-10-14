#!/usr/bin/env bash

# Bỏ qua kiểm tra tương thích compositor của Picom
export XSECURELOCK_COMPOSITOR_FLAG=1

# Đổi sang saver_mpv để phát video / slide ảnh
export XSECURELOCK_SAVER="saver_mpv"

# Chỉ định thư mục ảnh làm danh sách phát (trình chiếu ngẫu nhiên)
export XSECURELOCK_IMAGE_DIR="/home/fus/Pictures/Wallpapers"

# Tùy chỉnh tham số mpv: hiển thị mỗi ảnh 5 giây, lặp vô tận, xáo trộn thứ tự
export XSECURELOCK_SAVER_MPV_ARGS="--image-display-duration=5 --loop-playlist=inf --shuffle"

# Giao diện hộp thoại nhập mật khẩu
export XSECURELOCK_AUTH_BACKGROUND_COLOR="#161616"
export XSECURELOCK_AUTH_FOREGROUND_COLOR="#ffffff"
export XSECURELOCK_PAM_SERVICE="common-auth"

exec xsecurelock
