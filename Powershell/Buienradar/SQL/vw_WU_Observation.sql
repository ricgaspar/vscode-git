USE [WU]
GO

/****** Object:  View [dbo].[vw_WU_Observation]    Script Date: 11-8-2016 12:46:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[vw_WU_Observation]
AS
SELECT        dbo.WU_Observation.Systemname, dbo.WU_Observation.Domainname, 
			CONVERT(varchar(23), dbo.WU_Observation.PolDateTime, 121) as 'PolDateTime',
			dbo.WU_Observation.station_id, dbo.WU_Location.[full], dbo.WU_Location.latitude, 
                         dbo.WU_Location.longitude, dbo.WU_Location.elevation, dbo.WU_Observation.weather, dbo.WU_Observation.temp_c, dbo.WU_Observation.relative_humidity, dbo.WU_Observation.wind_dir, 
                         dbo.WU_Observation.wind_degrees, dbo.WU_Observation.wind_kph, dbo.WU_Observation.wind_gust_kph, dbo.WU_Observation.pressure_mb, dbo.WU_Observation.dewpoint_c, 
                         dbo.WU_Observation.feelslike_c, dbo.WU_Observation.visibility_km, dbo.WU_Observation.precip_1hr_metric, dbo.WU_Observation.precip_today_metric, dbo.WU_Observation.icon, 
                         dbo.WU_Observation.icon_url
FROM            dbo.WU_Location INNER JOIN
                         dbo.WU_Observation ON dbo.WU_Location.Systemname = dbo.WU_Observation.Systemname AND dbo.WU_Location.Domainname = dbo.WU_Observation.Domainname




GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "WU_Location"
            Begin Extent = 
               Top = 0
               Left = 57
               Bottom = 288
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "WU_Observation"
            Begin Extent = 
               Top = 14
               Left = 296
               Bottom = 295
               Right = 668
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 24
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1980
         Width = 1065
         Width = 975
         Width = 1155
         Width = 1710
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2265
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WU_Observation'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vw_WU_Observation'
GO


