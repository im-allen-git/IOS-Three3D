console.log(123)
function goPage( type ) {
    type = Number(type);
    switch (type) {
        case 1:
            $(".save_succ,.save_name_module_bg").hide();
            window.location.href = "ios:@1" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页
            break;
        case 2:
            window.location.href = "ios:@2" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页
            break;
        case 3:
            window.location.href = "ios:@3" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页
            break;
        case 4:
            window.location.href="ios:@4"
            break;
        case 5:
            window.location.href = "ios:@5" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页
            break;
            
        case 6:
            window.location.href = "ios:@6" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页 6 index页面
            break;
        case 7:
            window.location.href = "ios:@7" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页 6 index页面 7 3d打印机 状态页 status
            break;
        case 8:
            window.location.href = "ios:@8" ; //1,我的模型 2 商城 3 模型库首页 4 创建模型 5 返回上一页
            break;
            
    }
}
