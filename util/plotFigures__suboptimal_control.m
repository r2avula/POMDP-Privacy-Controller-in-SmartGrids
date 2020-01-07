function [] = plotFigures__suboptimal_control(controller_Params,evaluationDate,simulatedControllerData_50,simulatedControllerData_100)
slotIntervalInSeconds = controller_Params.slotIntervalInHours*3600; % in seconds
battery_consumption_50 = simulatedControllerData_50.battery_consumption;
battery_consumption_100 = simulatedControllerData_100.battery_consumption;
socs_50 = simulatedControllerData_50.socs;
socs_100 = simulatedControllerData_100.socs;
sm_consumption_original = simulatedControllerData_50.sm_consumption_original;
sm_consumption_modified_50 = simulatedControllerData_50.sm_consumption_modified;
sm_consumption_modified_100 = simulatedControllerData_100.sm_consumption_modified;
appliance_consumption_pu = simulatedControllerData_50.appliance_consumption_pu;
testEvaluationStart_slotIndex_in_day = controller_Params.testEvaluationStart_slotIndex_in_day;
testEvaluationEnd_slotIndex_in_day = controller_Params.testEvaluationEnd_slotIndex_in_day;
evaluation_interval = testEvaluationStart_slotIndex_in_day+1:testEvaluationEnd_slotIndex_in_day;
p_pu = controller_Params.p_pu;

savefiles = 0;
plot_battery_control = 1;
plot_consumption = 1;
plot_soc = 1;

if(plot_battery_control)
    filename = {'fig_bat_control'};
    
    time = zeros(length(battery_consumption_50),1);
    time_tick = round(length(time)/5)+1;
    time_tick(1) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), (evaluation_interval(1)-1)*slotIntervalInSeconds, 'second');
    j = 2;
    for i=1:length(battery_consumption_50)
        time(i) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), evaluation_interval(i)*slotIntervalInSeconds, 'second');
        if(mod(i,5)==0)
            time_tick(j) = time(i);
            j = j+1;
        end
    end
    
    
    figure_xsize = 900;
    figure_ysize = 500;
    fontSize = 14;
    
    figure_position_offset = 50;
    figure1 = figure('Color','w','Renderer','painters');
    set(gcf, 'Position',  [figure_position_offset,figure_position_offset,figure_position_offset+figure_xsize, figure_position_offset+figure_ysize]);
    
    % Create subplot
    subplot1 = subplot(2,1,1);
    hold(subplot1,'on');
    plot1 = plot(time,[appliance_consumption_pu'*p_pu battery_consumption_50'],'LineWidth',1.5);
    set(plot1(1),'DisplayName','Appliance consumption','Marker','o');
    set(plot1(2),'DisplayName','Battery consumption','Marker','square');
    ylabel({'Power (W)'},'Interpreter','latex');
    xlim(subplot1,[735196.333333333 735196.375]);
    ylim(subplot1,[-1500 2000]);
    box(subplot1,'on');
    
    % Set the remaining axes properties
    set(subplot1,'FontSize',fontSize,'TickLabelInterpreter','latex','XTick',...
        [735196.333333333 735196.340277778 735196.347222222 735196.354166667 735196.361111111 735196.368055556 735196.375],...
        'XTickLabel',...
        {' 8:00 AM',' 8:10 AM',' 8:20 AM',' 8:30 AM',' 8:40 AM',' 8:50 AM',' 9:00 AM'},...
        'YTick',[-1000 -500 0 500 1000 1500]);
    legend1 = legend(subplot1,'show');
    set(legend1,'FontSize',fontSize,'Interpreter','latex');
    
    % Create subplot
    subplot2 = subplot(2,1,2);
    hold(subplot2,'on');
    plot2 = plot(time,[appliance_consumption_pu'*p_pu battery_consumption_100'],'LineWidth',1.5);
    set(plot2(1),'DisplayName','Appliance consumption','Marker','o');
    set(plot2(2),'DisplayName','Battery consumption','Marker','square');
    ylabel({'Power (W)'},'Interpreter','latex');
    xlim(subplot2,[735196.333333333 735196.375]);
    ylim(subplot2,[-1500 2000]);
    box(subplot2,'on');
    
    % Set the remaining axes properties
    set(subplot2,'FontSize',fontSize,'TickLabelInterpreter','latex','XTick',...
        [735196.333333333 735196.340277778 735196.347222222 735196.354166667 735196.361111111 735196.368055556 735196.375],...
        'XTickLabel',...
        {' 8:00 AM',' 8:10 AM',' 8:20 AM',' 8:30 AM',' 8:40 AM',' 8:50 AM',' 9:00 AM'},...
        'YTick',[-1000 -500 0 500 1000 1500]);
    legend2 = legend(subplot2,'show');
    set(legend2,'FontSize',fontSize,'Interpreter','latex');
    
    % Create textarrow
    annotation(figure1,'textarrow',[0.445263157894737 0.396842105263158],...
        [0.652727272727273 0.68],...
        'String',{'Control action with','initial battery of 50% SOC'},...
        'HorizontalAlignment','left',...
        'FontSize',fontSize,...
        'FontName','Times New Roman');
    annotation(figure1,'textarrow',[0.441472039473684 0.395789473684211],...
        [0.172410878751761 0.196363636363636],...
        'String',{'Control action with','initial battery of 100% SOC'},...
        'HorizontalAlignment','left',...
        'FontSize',fontSize,...
        'FontName','Times New Roman');
    
    fig_pos = figure1.PaperPosition;
    figure1.PaperSize = [fig_pos(3) fig_pos(4)];
    
    if(savefiles)
        saveas(gcf,strcat(filename{1},'.fig'));
        saveas(gcf,strcat(filename{1},'.eps'),'epsc');
    end
end

if(plot_consumption)
    filename = {'fig_sm_readings'};
    
    time = zeros(length(sm_consumption_original),1);
    hour = 1:13;
    j = 2;
    hour(1) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), 0, 'second');
    for i=1:length(sm_consumption_original)
        time(i) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), (i)*slotIntervalInSeconds, 'second');
        if(mod(i,120) == 0)
            hour(j) = time(i);
            j = j+1;
        end
    end
    
    figure_xsize = 900;
    figure_ysize = 500;
    fontSize = 14;
    
    figure_position_offset = 50;
    figure1 = figure('Color','w','Renderer','painters');
    set(gcf, 'Position',  [figure_position_offset,figure_position_offset,figure_position_offset+figure_xsize, figure_position_offset+figure_ysize]);
    
    % Create subplot
    subplot1 = subplot(2,1,1);
    hold(subplot1,'on');
    plot1 = plot(time,[sm_consumption_original' sm_consumption_modified_50'],'LineWidth',1.5);
    set(plot1(1),'DisplayName','House consumption','LineStyle',':');
    set(plot1(2),'DisplayName','Smart meter measurement');
    ylabel({'Power (W)'},'Interpreter','latex');
    xlim(subplot1,[735196 735197]);
    ylim(subplot1,[-600 2100]);
    box(subplot1,'on');
    
    % Set the remaining axes properties
    set(subplot1,'FontSize',fontSize,'TickLabelInterpreter','latex','XTick',...
        [735196 735196.166666667 735196.333333333 735196.5 735196.666666667 735196.833333333 735197],...
        'XTickLabel',...
        {'12:00 AM',' 4:00 AM',' 8:00 AM','12:00 PM',' 4:00 PM',' 8:00 PM','12:00 AM'},'YTick',-500:500:2000);
    legend1 = legend(subplot1,'show');
    set(legend1,...
        'FontSize',fontSize,'Interpreter','latex');
    
    % Create subplot
    subplot2 = subplot(2,1,2);
    hold(subplot2,'on');
    plot2 = plot(time,[sm_consumption_original' sm_consumption_modified_100'],'LineWidth',1.5);
    set(plot2(1),'DisplayName','House consumption','LineStyle',':');
    set(plot2(2),'DisplayName','Smart meter measurement');
    ylabel({'Power (W)'},'Interpreter','latex');
    xlim(subplot2,[735196 735197]);
    ylim(subplot2,[-600 2100]);
    box(subplot2,'on');
    
    % Set the remaining axes properties
    set(subplot2,'FontSize',fontSize,'TickLabelInterpreter','latex','XTick',...
        [735196 735196.166666667 735196.333333333 735196.5 735196.666666667 735196.833333333 735197],...
        'XTickLabel',...
        {'12:00 AM',' 4:00 AM',' 8:00 AM','12:00 PM',' 4:00 PM',' 8:00 PM','12:00 AM'},'YTick',-500:500:2000);
    legend2 = legend(subplot2,'show');
    set(legend2,...
        'FontSize',fontSize,'Interpreter','latex');
    
    % Create textarrow
    annotation(figure1,'textarrow',[0.467302631578947 0.404281798245613],...
        [0.771785107714311 0.772202329602519],...
        'String',{'Reduced peak','with initial battery of 50% SOC'},...
        'HorizontalAlignment','left',...
        'FontSize',fontSize,...
        'FontName','Times New Roman');
    annotation(figure1,'textarrow',[0.465252192982456 0.406137609649122],...
        [0.288416912487709 0.301691248770893],...
        'String',{'Reduced peak','with initial battery of 100% SOC'},...
        'HorizontalAlignment','left',...
        'FontSize',fontSize,...
        'FontName','Times New Roman');
    
    fig_pos = figure1.PaperPosition;
    figure1.PaperSize = [fig_pos(3) fig_pos(4)];
    
    if(savefiles)
        saveas(gcf,strcat(filename{1},'.fig'));
        saveas(gcf,strcat(filename{1},'.eps'),'epsc');
    end
end

if(plot_soc)
    filename = {'fig_bat_soc'};
    
    time = zeros(length(battery_consumption_50),1);
    time_tick = round(length(time)/5)+1;
    time_tick(1) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), (evaluation_interval(1)-1)*slotIntervalInSeconds, 'second');
    j = 2;
    for i=1:length(battery_consumption_50)
        time(i) = addtodate(datenum(evaluationDate,'yyyy-mm-dd'), evaluation_interval(i)*slotIntervalInSeconds, 'second');
        if(mod(i,5)==0)
            time_tick(j) = time(i);
            j = j+1;
        end
    end
    
    
    figure_xsize = 900;
    figure_ysize = 250;
    fontSize = 14;
    
    figure_position_offset = 50;
    figure1 = figure('Color','w','Renderer','painters');
    set(gcf, 'Position',  [figure_position_offset,figure_position_offset,figure_position_offset+figure_xsize, figure_position_offset+figure_ysize]);
    
    % Create subplot
    subplot1 = subplot(1,1,1);
    hold(subplot1,'on');
    plot1 = plot(time,[socs_50' socs_100'],'LineWidth',1.5);
    set(plot1(1),'DisplayName','initialized with 50\% SOC');
    set(plot1(2),'DisplayName','initialized with 100\% SOC','LineStyle','--',...
        'Color',[1 0 0]);
    ylabel({'SOC'},'Interpreter','latex');
    xlim(subplot1,[735196.333333333 735196.375]);
    ylim(subplot1,[0.45 1]);
    box(subplot1,'on');
    
    % Set the remaining axes properties
    set(subplot1,'FontSize',fontSize,'TickLabelInterpreter','latex','XTick',...
        [735196.333333333 735196.340277778 735196.347222222 735196.354166667 735196.361111111 735196.368055556 735196.375],...
        'XTickLabel',...
        {' 8:00 AM',' 8:10 AM',' 8:20 AM',' 8:30 AM',' 8:40 AM',' 8:50 AM',' 9:00 AM'},...
        'YTick',0.5:0.1:1);
    legend1 = legend(subplot1,'show');
    set(legend1,'FontSize',fontSize,'Interpreter','latex','Location','southeast');
        
    fig_pos = figure1.PaperPosition;
    figure1.PaperSize = [fig_pos(3) fig_pos(4)];
    
    if(savefiles)
        saveas(gcf,strcat(filename{1},'.fig'));
        saveas(gcf,strcat(filename{1},'.eps'),'epsc');
    end
end
end

