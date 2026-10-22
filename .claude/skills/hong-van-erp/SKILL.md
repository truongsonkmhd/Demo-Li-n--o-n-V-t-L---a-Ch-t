---
name: hong-van-erp
description: Kiến thức và quy trình sửa bản demo Hồng Vân ERP (Hong_Van_ERP_Demo_Fixed.html — ERP cảng/logistics một file HTML). Dùng mỗi khi được yêu cầu phân tích, sửa, thêm tính năng, đổi giao diện, phân quyền hay dữ liệu của hệ thống ERP Hồng Vân / Cảng Hồng Vân trong thư mục này.
---

# Hồng Vân ERP — skill dự án

Bản demo ERP cho Cảng Hồng Vân, dùng để trình diễn cho khách hàng. Người dùng giao tiếp bằng **tiếng Việt** — trả lời và viết text giao diện bằng tiếng Việt có dấu.

## Quy trình mỗi lần sửa (bắt buộc)

1. Đọc mục **Quyết định đã chốt** và **Nhật ký thay đổi** dưới đây trước khi sửa — không làm ngược lại quyết định cũ.
2. File có thể đã được người dùng tự sửa ngoài phiên: `grep`/`Read` lại đoạn liên quan trước khi Edit, không dựa vào số dòng cũ.
3. Trước thay đổi lớn, sao lưu: `cp Hong_Van_ERP_Demo_Fixed.html <scratchpad>/backup_before_<tên>.html`.
4. Sửa xong chạy `bash .claude/skills/hong-van-erp/scripts/check.sh` (kiểm cú pháp JS + đăng nhập thử 4 vai trò trên Chrome headless). Thay đổi giao diện thì chụp màn hình kiểm tra (lệnh trong script).
5. **Cập nhật skill này**: thêm 1 dòng vào *Nhật ký thay đổi*, cập nhật *Phân quyền* / *Quyết định đã chốt* / *Tồn đọng* nếu bị ảnh hưởng (gạch khỏi Tồn đọng khi đã sửa). Skill phải luôn phản ánh đúng trạng thái hiện tại của file.
6. Báo lại cho người dùng ngắn gọn: đã sửa gì, đã kiểm tra thế nào, gợi ý bước tiếp (1 câu hỏi).

## Kiến trúc

- **Một file duy nhất** `Hong_Van_ERP_Demo_Fixed.html`: CSS (một dòng dài + vài rule bổ sung), HTML khung, một `<script>` cuối body. JS thuần, không framework, không build. Code viết dạng nén (nhiều lệnh/một dòng, template string) — giữ đúng phong cách đó khi sửa.
- **Lưu dữ liệu**: `localStorage` key `DBKEY='hongvan_erp_demo_v2_empty'`, qua `seedDB()` / `saveDB()`. Dữ liệu nghiệp vụ ban đầu trống.
- **Logo**: hằng `LOGO` (data URI base64, đầu script) gán vào mọi `img.app-logo` và `#favicon`. Nguồn: `logo.png` (logo ILS 512×512, nền trong suốt) — đã cắt lề, resize 160×160 rồi nhúng. Đổi logo = nhúng lại vào `LOGO`, không tham chiếu file ngoài (file HTML phải chạy độc lập).
- **Cấu hình theo metadata**: object `meta[key]` khai báo `title, singular, icon, desc, fields`. Field: `[name, label, type, opts, required]`, type ∈ `text|email|date|number|select|textarea|relation` (relation: `opts` = tên bảng). Cột bảng danh sách ở `moduleColumns()`. Thêm phân hệ CRUD = thêm vào `meta`, `moduleColumns`, `navItems`, mảng bảng trong `seedDB`, và `allowed` của vai trò.
- **Hàm chính**: `login/logout`, `buildNav` (lanhdao có menu viết tay riêng!), `go(page)` (kiểm quyền), `renderPage` (router), `renderReports`, `renderModule` (CRUD chung), `renderCustomerDetail/renderSupplierDetail`, `openForm` + submit handler của `#recordForm`, `deleteRecord`, `renderSettings`, `exportCSV/exportAll/importAll`.
- **Bộ lọc**: `state.search` (tìm không dấu qua `norm()`, khớp cả giá trị thô lẫn giá trị hiển thị `fieldValue` của mọi field trong `meta`), `state.filter` (trạng thái, 'all'), `state.filters={field:value}` (lọc theo nhóm, khai báo ở `filterFields[key]`). Options lấy bằng `fieldOptions(key,field)` = options trong `meta` ∪ giá trị có trong dữ liệu. Khi lọc chỉ gọi `refreshModule(key)` (thay `#moduleBody`, `#moduleCount`, nút `#clearFilters`), **không render lại cả trang**, để giữ focus và không làm hỏng bộ gõ tiếng Việt. Trang chi tiết KH/NCC dùng chung `renderPartnerDetail(key)` + `refreshPartnerDetail` với `state.detailSearch/detailFilter`. `go()` reset toàn bộ bộ lọc; `openDepartmentStaff(dept)` đặt `state.filters={department:dept}`. Ngày hiện tại dùng `localDate()` (giờ địa phương, không dùng `toISOString()` trực tiếp).
- **Quyền**: kiểm qua `users[state.user].allowed.includes(page)` (trong `go`). Nút `go(...)` mới trên trang dùng chung phải ẩn khi không có quyền.
- **Giao việc (`tasks`)**: field `kind` ('Lãnh đạo giao' nếu tạo bởi lanhdao, ngược lại 'Phòng ban tạo'; giữ nguyên khi sửa), `department` (options copy từ `meta.hr` department), `staffIds` (mảng, type `staff` → checkbox `staffPickerHtml`, lọc theo phòng ban + 'Đang làm việc'), `contractId` (chỉ HĐ 'Đang hiệu lực'), `assetId` (chỉ TS 'Đang hoạt động') qua `taskRelationSelect`, `start`, `end`, `status` ∈ Mới tạo / Đang thực hiện / Hoàn thành / Đã hủy, `createdBy`. Lãnh đạo giao: ẩn HĐ/TS, tạo mới ép 'Đang thực hiện'. **Bận** = nằm trong task có status thuộc `OPEN_TASK` (Mới tạo, Đang thực hiện), tính bằng `busyBy(field,id,exceptId)`; trong form, mục đang bận bị disable kèm mã CV; submit kiểm tra lại; không xóa được NV/TS/HĐ đang bận. Hoàn thành/Hủy/xóa task = giải phóng. Bận tính theo trạng thái, **không theo khoảng ngày**.
- **Báo cáo – thống kê bận/rảnh**: bảng phòng ban có cột Đang bận/Đang rảnh; panel "Nhân sự rảnh / bận" (lọc `state.rptStaff`, `state.rptStaffDept`); panel "Tài sản, máy móc đang làm / để không" (`state.rptAsset`: Đang làm / Để không = 'Đang hoạt động' và không bận / Không sẵn sàng = trạng thái khác).
- **Field bắt buộc**: field không có options khai báo `required` ở vị trí index 3 (`['code','Mã','text',true]`); `openForm` tự chuyển `opts===true` thành required.
- **Logic liên thông** (trong submit handler): phiếu cân → cộng `net` vào `shipment.actual`, chênh lệch → lô "Có sự cố"; lô "Hoàn thành" → tự tạo hồ sơ giao nhận; `contractPaid/contractBalance` tính từ finance "Thu tiền"/"Chi tiền" đã thanh toán.

## Phân quyền hiện tại (object `users`)

| Tài khoản | Vai trò | Trang đầu | allowed |
|---|---|---|---|
| lanhdao | Ban Giám đốc (= admin) | reports | reports, tasks, customers, suppliers, hr, assets |
| kinhdoanh | Phòng Kinh doanh | customers | customers, suppliers, contracts, shipments, tasks |
| khaithac | Phòng Khai thác | shipments | shipments, operations, weighing, documents, assets, tasks |
| tonghop | Phòng Tổng hợp | documents | documents, finance, assets, hr, tasks |

Mật khẩu chung `123456` (cứng trong submit `#loginForm`). Trang đầu = `allowed[0]`. Menu lanhdao viết tay trong `buildNav` (chỉ hiện Báo cáo, Giao việc, Khách hàng, NCC; hr/assets vào qua báo cáo). `users`/`settings` chưa vai trò nào có.

## Cơ cấu tổ chức thật (nguồn: `Quy dinh chuc nang nhiem vu phong ILSV 10.2026.docx`)

Công ty Cổ phần Cảng Hồng Vân (**ILSV**, thương hiệu **ILS / Interserco**; logo ILS là của công ty). Giám đốc: Mai Duy Chung. Dùng mục này làm căn cứ khi phân quyền, đặt tên phòng ban, bộ phận, chức danh.

- HĐQT (+ Thư ký HĐQT), Ban Kiểm soát → **Giám đốc** → **PGĐ Kinh doanh**, **PGĐ Đầu tư**.
- **P. Kinh doanh** (1 TP, 1 PP, 2 NV), bộ phận: KD kho bãi, KD cầu bến, KD logistics, KD thương mại. Việc: kế hoạch & chiến lược SXKD (năm/quý/tháng/tuần), nghiên cứu thị trường, kinh doanh dịch vụ hạ tầng cảng, lô hàng, kho bãi, logistics, thương mại; quản trị rủi ro; kế hoạch đầu tư vốn; **tổng hợp báo cáo kết quả SXKD** định kỳ/đột xuất.
- **P. Tổng hợp** (1 TP, 1 PP, 3 NV), bộ phận: BP kế toán, BP hành chính, BP bảo vệ. Việc: kế toán tài chính/quản trị (doanh thu, chi phí, công nợ, quỹ), quản trị tài chính, vốn góp, cổ đông, đầu tư tài chính; nhân sự (tuyển dụng, đào tạo, lương thưởng, đánh giá, thi đua, kỷ luật); hành chính, văn thư lưu trữ; ISO; ANTT, ATVSLĐ, PCCC; đầu tư mua sắm; kỹ thuật, quản lý CSHT, tài sản, trang thiết bị; tổng hợp báo cáo kế hoạch công việc các phòng.
- **P. Khai thác** (1 TP, 1 PP, 8 NV), bộ phận: KT kho bãi, KT cầu bến, KT 3PL, KT xếp dỡ, Tổ kỹ thuật. Việc: điều độ bốc xếp, nâng hạ; sắp xếp kho bãi; điều tiết tàu thuyền neo đậu, ra/vào cảng; vận hành dịch vụ tại cảng; sửa chữa sự cố thiết bị, điện, nước; kế hoạch bảo dưỡng, mua sắm, thay thế phụ tùng; tìm và phát triển khách thuê kho bãi; xử lý phát sinh với khách.

## Quyết định đã chốt

- Không hiển thị text nhắc tới LocalStorage / "lưu trên trình duyệt" / "dữ liệu demo trống" trên giao diện.
- Không hiển thị khung "Tài khoản demo (mật khẩu chung…)" ở màn hình đăng nhập.
- Bỏ notice "sổ theo dõi quản trị demo, không thay thế phần mềm kế toán" ở Tài chính. Hướng chung: tránh text tự nhận "chỉ là demo" trên giao diện.
- **lanhdao được coi là admin**. Chỉ lanhdao có Báo cáo quản trị; các phòng ban khác không có.
- Phân hệ Giao việc không có dòng mô tả (`desc:''`) và không có notice trong form. Không thêm text giải thích kiểu này lại.
- **Đã bỏ hẳn trang Tổng quan (dashboard)**: không thêm lại trừ khi người dùng yêu cầu.
- Logo ILS nhúng base64 (xem Kiến trúc). Tên hiển thị vẫn "HỒNG VÂN ERP".
- Phòng ban Nhân sự (`meta.hr` field `department`): Ban Giám đốc, Phòng Kinh doanh, Phòng Khai thác, Phòng Tổng hợp, **Tổ bốc xếp** (người dùng bổ sung, không có trong sơ đồ tổ chức văn bản). Danh sách `departments` trong `renderReports` phải đồng bộ với danh sách này.

## Tồn đọng (lỗi/bất cập đã biết, chưa sửa)

- Giao việc: "Kế hoạch khai thác" vẫn ghi đầu mối/thiết bị bằng text, chưa liên kết với Giao việc → người/máy trong kế hoạch khai thác không tính là bận. Chưa có bận theo khoảng ngày; mọi phòng ban đều xem/sửa được mọi công việc.

- `users`, `settings` không vai trò nào truy cập được → không dùng được nhập JSON, khôi phục, đổi tên công ty. (Đã đề xuất thêm cho lanhdao, chờ người dùng xác nhận.)
- Đăng nhập dùng object `users` cứng, không đọc `db.users` → thêm/khóa tài khoản không có tác dụng.
- `logout()` tự điền lại mật khẩu `123456`.
- `openForm` không kiểm quyền (lanhdao tạo/sửa được hợp đồng từ trang chi tiết KH); chưa có quyền theo thao tác (xem/thêm/sửa/xóa/duyệt).
- `renderReports` còn phòng ban 'Lái xe' không tồn tại trong field `hr.department` → luôn 0.
- Sửa/xóa phiếu cân không tính lại `actual` của lô cũ.
- `deleteRecord` thiếu kiểm tra tham chiếu: KH ↔ lô hàng, finance ↔ KH/NCC/hợp đồng/lô.
- Báo cáo tính công nợ = giá trị HĐ − đã thu, bỏ qua bản ghi finance `Phải thu`/`Phải trả`; HĐ Dự thảo/Tạm dừng vẫn tính công nợ.
- "Giá trị hợp đồng có hiệu lực trong tháng" thực ra lọc theo ngày bắt đầu.
- CSS `.link-button` khai báo 3 lần, bản sau dùng `var(--primary)` không tồn tại → link không có màu xanh.
- Dropdown relation không lọc theo ngữ cảnh (hợp đồng của lô hiện cả HĐ chi / HĐ KH khác).
- Field `contracts.limit` mang nhãn "Nội dung hợp đồng"; `documents.relatedCode` là text tự do.
- Notice trang Cân còn câu "Bản demo chưa kết nối trực tiếp với cân điện tử" (đã hỏi người dùng có bỏ không).
- Ý tưởng nâng cấp: nút nạp dữ liệu mẫu, luồng phê duyệt hợp đồng, trang chi tiết lô hàng dạng timeline, tự sinh Phải thu từ lô hoàn thành, cảnh báo hết hạn, biểu đồ.

## Nhật ký thay đổi

- 2026-10-21 — Bỏ text LocalStorage (login-note, chân sidebar, trang Cấu hình, notice giới hạn).
- 2026-10-21 — Bỏ khung "Tài khoản demo" ở màn hình đăng nhập. (Người dùng tự đổi placeholder ô tài khoản thành "Nhập tài khoản".)
- 2026-10-21 — Thay chữ "HV" bằng logo ILS nhúng base64 (login, sidebar, favicon).
- 2026-10-21 — Bỏ notice "sổ theo dõi quản trị demo…" ở Tài chính.
- 2026-10-21 — Chỉ lanhdao có Tổng quan + Báo cáo; trang đầu theo `allowed[0]`; thêm `can()`/`navBtn()`; sửa thiếu `</div>` ở khung "Cần theo dõi".
- 2026-10-21 — Tạo skill này + `scripts/check.sh`.
- 2026-10-21 — Đọc quy định chức năng nhiệm vụ ILSV, thêm mục *Cơ cấu tổ chức thật* (chưa sửa code).
- 2026-10-21 — Sửa toàn bộ bộ lọc: tìm không dấu + theo ngày/tiền/tên liên kết; trạng thái đủ options; thêm lọc nhóm theo `filterFields` (HR có Phòng ban, Chức danh); nút Xóa bộ lọc; đếm x / tổng; lọc không render lại trang; gộp chi tiết KH/NCC vào `renderPartnerDetail`; bỏ `state.hrDepartment`; `localDate()` thay UTC. Đã test 16 ca bằng Chrome headless.
- 2026-10-21 — Thêm phòng ban "Tổ bốc xếp" vào form Nhân sự; báo cáo thay "Nhân sự bốc vác" bằng "Tổ bốc xếp".
- 2026-10-21 — Bỏ trang Tổng quan (dashboard): xóa `renderDashboard`, `can`, `navBtn`, mục menu, quyền; lanhdao vào thẳng Báo cáo quản trị.
- 2026-10-21 — Thêm phân hệ Giao việc (`tasks`) cho cả 4 vai trò + chặn chọn trùng NV/HĐ/TS đang bận + thống kê bận/rảnh trong Báo cáo. Sửa lỗi cũ: ô bắt buộc kiểu text không được bắt buộc. Test 19 ca Chrome headless.
- 2026-10-22 — Bỏ mô tả trang Giao việc và notice "Công việc do lãnh đạo giao…" trong form.
