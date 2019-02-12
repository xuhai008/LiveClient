/*
 * author: Alex
 *   date: 2018-04-18
 *   file: RecvCancelProgramNoticeTask.cpp
 *   desc: 11.2.节目取消通知Task实现类
 */

#include "RecvCancelProgramNoticeTask.h"
#include "ITaskManager.h"
#include "IImClient.h"
#include "AmfPublicParse.h"
#include <json/json/json.h>
#include <common/KLog.h>
#include <common/CheckMemoryLeak.h>
// 返回参数定义
#define RECVCPN_SHOWINFO_PARAM               "show_info"

RecvCancelProgramNoticeTask::RecvCancelProgramNoticeTask(void)
{
	m_listener = NULL;

	m_seq = 0;
	m_errType = LCC_ERR_FAIL;
	m_errMsg = "";
}

RecvCancelProgramNoticeTask::~RecvCancelProgramNoticeTask(void)
{
}

// 初始化
bool RecvCancelProgramNoticeTask::Init(IImClientListener* listener)
{
	bool result = false;
	if (NULL != listener)
	{
		m_listener = listener;
		result = true;
	}
	return result;
}
	
// 处理已接收数据
bool RecvCancelProgramNoticeTask::Handle(const TransportProtocol& tp)
{
	bool result = false;

	FileLog("ImClient", "RecvCancelProgramNoticeTask::Handle() begin, tp.isRespond:%d, tp.cmd:%s, tp.reqId:%d"
            , tp.m_isRespond, tp.m_cmd.c_str(), tp.m_reqId);
	
    // 协议解析
    IMProgramItem item;
    if (!tp.m_isRespond) {
        result = (LCC_ERR_PROTOCOLFAIL != tp.m_errno);
		m_errType = (LCC_ERR_TYPE)tp.m_errno;
        m_errMsg = tp.m_errmsg;
        if (tp.m_data[RECVCPN_SHOWINFO_PARAM].isObject()) {
            item.Parse(tp.m_data[RECVCPN_SHOWINFO_PARAM]);
        }

    }
    
    // 协议解析失败
    if (!result) {
		m_errType = LCC_ERR_PROTOCOLFAIL;
		m_errMsg = "";
	}

	FileLog("ImClient", "RecvCancelProgramNoticeTask::Handle() m_errType:%d", m_errType);

	// 通知listener
	if (NULL != m_listener) {
       m_listener->OnRecvCancelProgramNotice(item);
		FileLog("ImClient", "RecvCancelProgramNoticeTask::Handle() callback end, result:%d", result);
	}
	
	FileLog("ImClient", "RecvCancelProgramNoticeTask::Handle() end");

	return result;
}
	
// 获取待发送的Json数据
bool RecvCancelProgramNoticeTask::GetSendData(Json::Value& data)
{
	bool result = false;
	
	FileLog("ImClient", "RecvCancelProgramNoticeTask::GetSendData() begin");
    {
        // 构造json协议
        Json::Value value;
        value[ROOT_ERRNO] = (int)m_errType;
        if (m_errType != LCC_ERR_SUCCESS) {
            value[ROOT_ERRMSG] = m_errMsg;
        }
        data = value;
    }

    result = true;

	FileLog("ImClient", "RecvCancelProgramNoticeTask::GetSendData() end, result:%d", result);

	return result;
}

// 获取命令号
string RecvCancelProgramNoticeTask::GetCmdCode() const
{
	return CMD_RECVCANCELPROGRAMNOTICE;
}

// 设置seq
void RecvCancelProgramNoticeTask::SetSeq(SEQ_T seq)
{
	m_seq = seq;
}

// 获取seq
SEQ_T RecvCancelProgramNoticeTask::GetSeq() const
{
	return m_seq;
}

// 是否需要等待回复。若false则发送后释放(delete掉)，否则发送后会被添加至待回复列表，收到回复后释放
bool RecvCancelProgramNoticeTask::IsWaitToRespond() const
{
	return false;
}

// 获取处理结果
void RecvCancelProgramNoticeTask::GetHandleResult(LCC_ERR_TYPE& errType, string& errMsg)
{
	errType = m_errType;
	errMsg = m_errMsg;
}


// 未完成任务的断线通知
void RecvCancelProgramNoticeTask::OnDisconnect()
{

}